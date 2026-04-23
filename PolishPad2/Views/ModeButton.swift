import SwiftUI

/// Primary polish button — the visually privileged action tier.
/// 60pt tall, 16pt continuous corners, opaque off-white fill with a clearly
/// visible border when inactive, accent fill when active. Calibrated for
/// users who benefit from unambiguous button edges and high-contrast labels.
struct PrimaryPolishButton: View {
    let title: String
    let isActive: Bool
    let isAnyActive: Bool
    let isEnabled: Bool
    let onTap: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: onTap) {
                HStack(spacing: 10) {
                    Text(labelText)
                        .font(.system(size: 18, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    if isActive {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                }
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .padding(.horizontal, 18)
                .padding(.trailing, isActive ? 40 : 18)
                .background(backgroundLayer)
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled || isActive)
            .shadow(
                color: isActive
                    ? Color.polishPadAccent.opacity(0.26)
                    : Color.black.opacity(0.08),
                radius: isActive ? 14 : 8,
                y: isActive ? 5 : 3
            )

            if isActive {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .padding(.trailing, 12)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel polish")
            }
        }
        .opacity(dimOpacity)
        .animation(.easeInOut(duration: 0.2), value: isActive)
        .animation(.easeInOut(duration: 0.2), value: isAnyActive)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }

    private var labelText: String {
        isActive ? "Polishing…" : title
    }

    private var foregroundColor: Color {
        isActive ? .white : .primary
    }

    private var dimOpacity: Double {
        if isActive { return 1.0 }
        if isAnyActive { return 0.5 }
        if !isEnabled { return 0.4 }
        return 1.0
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if isActive {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.polishPadAccent)
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.polishPadButtonSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.polishPadBorder, lineWidth: 1.5)
                )
        }
    }
}

/// Secondary utility button — clearly visible outlined button.
/// Designed so older users and users recovering from strokes can see and
/// target each action unambiguously. Smaller and quieter than the primary
/// row but unambiguously a button, not dim text.
struct UtilityButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            UtilityButtonLabel(title: title, isEnabled: isEnabled)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.18), value: isEnabled)
    }
}

/// Shared label treatment for utility-tier buttons. Used by `UtilityButton`
/// and by `ShareLink` so the Share action matches the rest of the secondary row.
struct UtilityButtonLabel: View {
    let title: String
    let isEnabled: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(isEnabled ? Color.primary : Color.primary.opacity(0.35))
            .lineLimit(1)
            .minimumScaleFactor(0.9)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.polishPadButtonSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isEnabled ? Color.polishPadBorder : Color.polishPadBorder.opacity(0.4),
                        lineWidth: 1.25
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 4, y: 1)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
