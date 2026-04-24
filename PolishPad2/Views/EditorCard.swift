import SwiftUI

struct EditorialEditorCanvasView: View {
    @Binding var selectedSurface: EditorSurface
    @Binding var sourceText: String
    @Binding var polishedText: String
    @FocusState.Binding var editorIsFocused: Bool
    let minHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            headerRow
            canvasBody
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: PolishPadLayout.outerCorner, style: .continuous)
                .fill(Color.ppCanvas)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PolishPadLayout.outerCorner, style: .continuous)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
        .shadow(color: Color.ppWarmShadow.opacity(0.07), radius: 26, y: 12)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 12) {
            Spacer(minLength: 0)
            surfacePicker
        }
    }

    private var surfacePicker: some View {
        HStack(spacing: 0) {
            ForEach(EditorSurface.allCases) { surface in
                surfaceSegment(for: surface)
            }
        }
        .padding(5)
        .background(
            Capsule()
                .fill(Color.ppBackground.opacity(0.65))
        )
        .overlay(
            Capsule()
                .stroke(Color.ppBorder, lineWidth: 1)
        )
        .shadow(color: Color.ppWarmShadow.opacity(0.04), radius: 8, y: 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Draft or Result")
        .accessibilityHint("Switches between the original draft and polished result.")
    }

    private func surfaceSegment(for surface: EditorSurface) -> some View {
        let isSelected = selectedSurface == surface

        return Button {
            selectedSurface = surface
        } label: {
            Text(surface.title)
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundStyle(isSelected ? Color.ppAccent : Color.ppSecondaryText)
                .frame(width: 116, height: 38)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.ppCardSoft : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.ppBorder : Color.clear, lineWidth: 1)
                )
                .shadow(
                    color: isSelected ? Color.ppWarmShadow.opacity(0.08) : Color.clear,
                    radius: 7,
                    y: 2
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(surface.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Body

    private var canvasBody: some View {
        ZStack(alignment: .topLeading) {
            if isActiveTextEmpty {
                emptyStateOverlay
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: minHeight)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            TextEditor(text: activeText)
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(Color.ppText)
                .tint(Color.ppAccent)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .frame(minHeight: minHeight)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .writingToolsBehavior(.complete)
                .focused($editorIsFocused)
                .accessibilityLabel(selectedSurface.title)
        }
        .animation(.easeOut(duration: 0.18), value: isActiveTextEmpty)
    }

    // MARK: - Empty states

    @ViewBuilder
    private var emptyStateOverlay: some View {
        switch selectedSurface {
        case .draft:
            draftEmptyState
        case .result:
            resultEmptyState
        }
    }

    private var draftEmptyState: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)
            ZStack {
                Circle()
                    .fill(Color.ppCanvas)
                    .frame(width: 76, height: 76)
                    .overlay(
                        Circle()
                            .stroke(Color.ppBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.ppWarmShadow.opacity(0.06), radius: 12, y: 5)

                Image(systemName: "mic")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color.ppAccent)
            }
            Text("Start typing, or tap the mic to dictate.")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.ppSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer(minLength: 0)
        }
    }

    private var resultEmptyState: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)
            Text("Your polished result will appear here.")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.ppSecondaryText.opacity(0.82))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Helpers

    private var activeText: Binding<String> {
        switch selectedSurface {
        case .draft:
            $sourceText
        case .result:
            $polishedText
        }
    }

    private var isActiveTextEmpty: Bool {
        activeText.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
