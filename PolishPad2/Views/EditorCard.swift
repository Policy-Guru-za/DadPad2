import SwiftUI

struct EditorCard<Trailing: View>: View {
    let title: String
    let caption: String
    let placeholder: String
    let minHeight: CGFloat
    @Binding var text: String
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(caption)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                trailing()
            }

            ZStack(alignment: .topLeading) {
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(placeholder)
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 10)
                        .accessibilityHidden(true)
                }

                TextEditor(text: $text)
                    .font(.title3)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: minHeight)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .writingToolsBehavior(.complete)
                    .accessibilityLabel(title)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(22)
        .background(cardBackground)
        .overlay(cardOutline)
        .shadow(color: Color.black.opacity(0.04), radius: 18, y: 8)
    }

    private var cardBackground: some ShapeStyle {
        .regularMaterial
    }

    private var cardOutline: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(Color.white.opacity(0.6), lineWidth: 1)
    }
}
