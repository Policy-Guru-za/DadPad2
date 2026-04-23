import SwiftUI

struct EditorialEditorCanvasView: View {
    @Binding var selectedSurface: EditorSurface
    @Binding var sourceText: String
    @Binding var polishedText: String
    @FocusState.Binding var editorIsFocused: Bool
    let minHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow
            canvasBody
        }
        .padding(20)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator).opacity(0.6), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 16, y: 4)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 12) {
            Spacer(minLength: 0)
            surfacePicker
        }
    }

    private var surfacePicker: some View {
        Picker("Surface", selection: $selectedSurface) {
            ForEach(EditorSurface.allCases) { surface in
                Text(surface.title).tag(surface)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(maxWidth: 240)
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
                .foregroundStyle(.primary)
                .tint(Color.polishPadAccent)
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
            Image(systemName: "mic")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(.tertiary)
            Text("Start typing, or tap the mic to dictate.")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.secondary)
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
                .foregroundStyle(.tertiary)
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
