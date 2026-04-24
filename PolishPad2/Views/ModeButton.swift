import SwiftUI

struct PrimaryPolishButton: View {
    let mode: PolishMode
    let isActive: Bool
    let isAnyActive: Bool
    let isEnabled: Bool
    let onTap: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                HStack(spacing: 18) {
                    iconBadge

                    Text(labelText)
                        .font(.system(size: 19, weight: .semibold, design: .serif))
                        .foregroundStyle(labelColor)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if isActive {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color.ppAccent)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 96)
                .padding(.horizontal, 24)
                .padding(.trailing, isActive ? 48 : 24)
                .background(backgroundLayer)
                .contentShape(RoundedRectangle(cornerRadius: PolishPadLayout.cardCorner, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled || isActive)
            .shadow(
                color: isActive
                    ? Color.ppAccent.opacity(0.18)
                    : Color.ppWarmShadow.opacity(0.08),
                radius: isActive ? 16 : 12,
                y: isActive ? 7 : 5
            )
            .accessibilityLabel(mode.dockTitle)
            .accessibilityHint(isActive ? "Polishing. Double tap cancel to stop." : "Polishes the draft for \(mode.shortTitle.lowercased()).")

            if isActive {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(Color.ppAccent.opacity(0.8))
                        .padding(12)
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
        isActive ? "Polishing..." : mode.dockTitle
    }

    private var dimOpacity: Double {
        if isActive { return 1.0 }
        if isAnyActive { return 0.56 }
        if !isEnabled { return 0.94 }
        return 1.0
    }

    private var labelColor: Color {
        isEnabled || isActive ? Color.ppText : Color.ppText.opacity(0.68)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(Color.ppCardSoft.opacity(0.88))
                .frame(width: 56, height: 56)
                .overlay(
                    Circle()
                        .stroke(Color.ppAccentSoft.opacity(0.32), lineWidth: 1)
                )

            Image(systemName: mode.symbolName)
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(Color.ppAccent)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        let shape = RoundedRectangle(cornerRadius: PolishPadLayout.cardCorner, style: .continuous)

        if isActive {
            shape
                .fill(
                    LinearGradient(
                        colors: [Color.ppCard, Color.ppCardSoft],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(shape.stroke(Color.ppAccent.opacity(0.34), lineWidth: 1.25))
        } else {
            shape
                .fill(
                    LinearGradient(
                        colors: [Color.ppCardSoft, Color.ppCard],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(shape.stroke(Color.ppBorder, lineWidth: 1))
        }
    }
}

struct SecondaryActionToolbar: View {
    let canUndo: Bool
    let canCopy: Bool
    let canClear: Bool
    let sharePayload: PolishSharePayload?
    let undo: () -> Void
    let copy: () -> Void
    let clear: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            toolbarButton(title: "Undo", symbolName: "arrow.uturn.backward", isEnabled: canUndo, action: undo)
            divider
            toolbarButton(title: "Copy", symbolName: "doc.on.doc", isEnabled: canCopy, action: copy)
            divider
            shareControl
            divider
            toolbarButton(title: "Clear", symbolName: "trash", isEnabled: canClear, action: clear)
        }
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: PolishPadLayout.toolbarCorner, style: .continuous)
                .fill(Color.ppCanvas)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PolishPadLayout.toolbarCorner, style: .continuous)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
        .shadow(color: Color.ppWarmShadow.opacity(0.045), radius: 10, y: 4)
        .animation(.easeInOut(duration: 0.18), value: canUndo)
        .animation(.easeInOut(duration: 0.18), value: canCopy)
        .animation(.easeInOut(duration: 0.18), value: canClear)
        .animation(.easeInOut(duration: 0.18), value: sharePayload)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.ppBorder)
            .frame(width: 1)
            .padding(.vertical, 1)
    }

    @ViewBuilder
    private var shareControl: some View {
        if let payload = sharePayload {
            ShareLink(item: payload.text, subject: Text(payload.subject)) {
                UtilityButtonLabel(title: "Share", symbolName: "square.and.arrow.up", isEnabled: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share")
        } else {
            toolbarButton(title: "Share", symbolName: "square.and.arrow.up", isEnabled: false, action: {})
        }
    }

    private func toolbarButton(
        title: String,
        symbolName: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            UtilityButtonLabel(title: title, symbolName: symbolName, isEnabled: isEnabled)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(title)
    }
}

struct UtilityButtonLabel: View {
    let title: String
    let symbolName: String
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 22, weight: .regular))
                .accessibilityHidden(true)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(isEnabled ? Color.ppToolbarText : Color.ppToolbarText.opacity(0.68))
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .contentShape(Rectangle())
    }
}
