import SwiftUI

struct ModeButton: View {
    let mode: PolishMode
    let isRunning: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: mode.symbolName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(isRunning ? Color.white : Color.accentColor)

                    Spacer()

                    if isRunning {
                        ProgressView()
                            .tint(.white)
                            .controlSize(.small)
                    }
                }

                Text(mode.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isRunning ? Color.white : Color.primary)
                    .multilineTextAlignment(.leading)

                Text(mode.helpText)
                    .font(.subheadline)
                    .foregroundStyle(isRunning ? Color.white.opacity(0.92) : Color.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
            .padding(18)
            .background(background)
            .overlay(outline)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode.title)
        .accessibilityHint(mode.helpText)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                isRunning
                    ? LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [
                            Color(uiColor: .secondarySystemBackground),
                            Color(uiColor: .secondarySystemBackground).opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
    }

    private var outline: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(
                isRunning ? Color.white.opacity(0.36) : Color.white.opacity(0.7),
                lineWidth: 1
            )
    }
}
