import SwiftUI

/// Slim inline status rail. Rendered ONLY for processing, fallback, and error states.
/// Ready and copied states are handled elsewhere (copied appears as a transient toast).
struct StatusRailView: View {
    let status: WorkflowStatusState
    var onRetry: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            leadingGlyph

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(messageColor)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 8)

            if case .error = status, let onRetry {
                Button("Retry", action: onRetry)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(.systemRed))
                    .buttonStyle(.plain)
                    .accessibilityLabel("Retry last polish")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 36)
        .background(Color.ppCanvas.opacity(0.96))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.ppBorder)
                .frame(height: 0.5)
        }
    }

    @ViewBuilder
    private var leadingGlyph: some View {
        switch status {
        case .processing:
            ProgressView()
                .controlSize(.small)
                .tint(Color.ppAccent)
        case .fallback:
            Image(systemName: "bolt.slash")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.ppSecondaryText)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(.systemRed))
        case .ready, .copied:
            EmptyView()
        }
    }

    private var message: String {
        switch status {
        case let .processing(mode):
            "Polishing your \(mode.shortTitle.lowercased())…"
        case let .fallback(reason):
            reason
        case let .error(message):
            message
        case .ready, .copied:
            ""
        }
    }

    private var messageColor: Color {
        switch status {
        case .error:
            Color(.systemRed)
        case .processing, .fallback, .ready, .copied:
            Color.ppSecondaryText
        }
    }
}

/// Transient confirmation that the polished result was copied.
/// Appears above the dock for ~1.6s (handled by the model).
struct CopiedToastView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(.systemGreen))

            Text("Copied to clipboard")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.ppText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.ppCanvas, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.ppBorder, lineWidth: 0.5)
        )
        .shadow(color: Color.ppWarmShadow.opacity(0.08), radius: 10, y: 2)
    }
}
