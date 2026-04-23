import SwiftUI

struct EditorialEditorCanvasView: View {
    @Binding var selectedSurface: EditorSurface
    @Binding var sourceText: String
    @Binding var polishedText: String
    let capability: PolishCapability
    let caption: String
    let lastCompletedMode: PolishMode?
    let minHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedSurface.canvasTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.polishPadNavy)

                    Text(caption)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Color.polishPadNavy.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 12) {
                    surfacePicker

                    if selectedSurface == .result {
                        capabilityBadge
                    }
                }
            }

            ZStack(alignment: .topLeading) {
                if activeText.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(selectedSurface.placeholder)
                        .font(.system(size: 22, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.polishPadMutedText.opacity(0.72))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 28)
                        .accessibilityHidden(true)
                }

                TextEditor(text: activeText)
                    .font(.system(size: 24, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.polishPadNavy)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .frame(minHeight: minHeight)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .writingToolsBehavior(.complete)
                    .accessibilityLabel(selectedSurface.canvasTitle)
            }
            .background(innerBackground, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(Color.polishPadStroke.opacity(0.72), lineWidth: 1.2)
            )
        }
        .padding(22)
        .background(outerBackground, in: RoundedRectangle(cornerRadius: 40, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .stroke(Color.polishPadStroke.opacity(0.78), lineWidth: 1.4)
        )
        .shadow(color: Color.polishPadGlow.opacity(0.16), radius: 34, y: 14)
    }

    private var activeText: Binding<String> {
        switch selectedSurface {
        case .draft:
            $sourceText
        case .result:
            $polishedText
        }
    }

    private var surfacePicker: some View {
        HStack(spacing: 8) {
            ForEach(EditorSurface.allCases) { surface in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) {
                        selectedSurface = surface
                    }
                } label: {
                    Text(surface.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(surface == selectedSurface ? Color.polishPadNavy : Color.polishPadMutedText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(
                            Capsule()
                                .fill(surface == selectedSurface ? Color.polishPadPaper : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Color.polishPadShell.opacity(0.72), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.polishPadStroke.opacity(0.55), lineWidth: 1)
        )
    }

    private var capabilityBadge: some View {
        let badgeColor = capability.usesFoundationModel ? Color.polishPadNavy : Color.polishPadTerracotta

        return HStack(spacing: 8) {
            Circle()
                .fill(badgeColor)
                .frame(width: 8, height: 8)

            Text(lastCompletedMode.map { "\($0.shortTitle) • \(capability.outputBadgeText)" } ?? capability.outputBadgeText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(badgeColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(badgeColor.opacity(0.08), in: Capsule())
    }

    private var outerBackground: some ShapeStyle {
        LinearGradient(
            colors: [Color.polishPadPaper.opacity(0.98), Color.polishPadPaper.opacity(0.84)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var innerBackground: some ShapeStyle {
        LinearGradient(
            colors: [Color.polishPadPaper.opacity(0.98), Color.white.opacity(0.58)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
