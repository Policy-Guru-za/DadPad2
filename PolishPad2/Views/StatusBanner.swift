import SwiftUI

struct StatusRailView: View {
    let status: WorkflowStatusState

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            Text(status.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .tracking(1.4)

            Text(status.message)
                .font(.system(size: 21, weight: .medium, design: .rounded))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            if case .processing = status {
                ProgressView()
                    .tint(foregroundColor)
                    .controlSize(.regular)
            }
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(backgroundColor, in: Capsule())
        .overlay(
            Capsule()
                .stroke(borderColor, lineWidth: 1.2)
        )
        .shadow(color: Color.polishPadGlow.opacity(0.12), radius: 24, y: 8)
    }

    private var backgroundColor: Color {
        switch status {
        case .ready, .processing:
            Color.polishPadTeal
        case .fallback:
            Color(red: 0.959, green: 0.906, blue: 0.802)
        case .error:
            Color(red: 0.959, green: 0.842, blue: 0.817)
        case .copied:
            Color(red: 0.867, green: 0.919, blue: 0.836)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .ready, .processing, .fallback:
            Color.polishPadNavy
        case .error:
            Color(red: 0.498, green: 0.162, blue: 0.151)
        case .copied:
            Color(red: 0.182, green: 0.35, blue: 0.204)
        }
    }

    private var borderColor: Color {
        switch status {
        case .ready, .processing:
            Color.polishPadStroke.opacity(0.78)
        case .fallback:
            Color(red: 0.863, green: 0.699, blue: 0.475)
        case .error:
            Color(red: 0.831, green: 0.573, blue: 0.512)
        case .copied:
            Color(red: 0.572, green: 0.738, blue: 0.542)
        }
    }
}
