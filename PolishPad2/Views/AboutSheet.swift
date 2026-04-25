import SwiftUI

enum AppLinks {
    static let privacyPolicy = URL(string: "https://redcliffebay.com/polishpad/privacy")!
    static let support = URL(string: "https://redcliffebay.com/polishpad/support")!
    static let supportEmail = "support@redcliffebay.com"
    static let supportEmailURL = URL(string: "mailto:\(supportEmail)")!
}

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                linkPanel
                privacyNote
            }
            .padding(.horizontal, 34)
            .padding(.top, 30)
            .padding(.bottom, 42)
            .frame(maxWidth: 660, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(Color.ppBackground.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 18) {
                Text("PolishPad")
                    .font(.system(size: 36, weight: .regular, design: .serif))
                    .foregroundStyle(Color.ppText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 12)

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.ppAccent)
                        .padding(.horizontal, 18)
                        .frame(height: 44)
                        .background(Color.ppCardSoft.opacity(0.78), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.ppBorder.opacity(0.7), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close About")
            }

            Text("PolishPad is a private iPad writing utility that helps users turn rough typed or dictated text into clearer notes, emails, and messages.")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.ppSecondaryText)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var linkPanel: some View {
        VStack(spacing: 0) {
            AppLinkRow(
                title: "Privacy Policy",
                subtitle: AppLinks.privacyPolicy.absoluteString,
                symbolName: "lock.shield",
                destination: AppLinks.privacyPolicy
            )

            Divider()
                .overlay(Color.ppBorder)

            AppLinkRow(
                title: "Support",
                subtitle: AppLinks.support.absoluteString,
                symbolName: "questionmark.circle",
                destination: AppLinks.support
            )

            Divider()
                .overlay(Color.ppBorder)

            AppLinkRow(
                title: "Email Support",
                subtitle: AppLinks.supportEmail,
                symbolName: "envelope",
                destination: AppLinks.supportEmailURL
            )
        }
        .background(Color.ppCanvas, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
        .shadow(color: Color.ppWarmShadow.opacity(0.055), radius: 16, y: 7)
    }

    private var privacyNote: some View {
        Text("Polishing happens on device with Apple Intelligence on a compatible iPad. PolishPad does not require an account, backend, or cloud AI service.")
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(Color.ppSecondaryText)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 2)
    }
}

private struct AppLinkRow: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: symbolName)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.ppAccent)
                    .frame(width: 38, height: 38)
                    .background(Color.ppCardSoft.opacity(0.74), in: Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.ppBorder.opacity(0.65), lineWidth: 1)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.ppText)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.ppSecondaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 12)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.ppAccent.opacity(0.78))
                    .frame(width: 26, height: 26)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(title)
        .accessibilityHint("Opens externally.")
    }
}

#Preview {
    AboutSheet()
}
