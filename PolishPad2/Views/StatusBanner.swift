import SwiftUI

struct StatusBannerView: View {
    enum Kind {
        case warning
        case error
    }

    let title: String
    let message: String
    let kind: Kind

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: iconName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(strokeColor, lineWidth: 1)
        )
    }

    private var iconName: String {
        switch kind {
        case .warning:
            "sparkles.rectangle.stack"
        case .error:
            "exclamationmark.triangle"
        }
    }

    private var iconColor: Color {
        switch kind {
        case .warning:
            Color.orange
        case .error:
            Color.red
        }
    }

    private var backgroundColor: Color {
        switch kind {
        case .warning:
            Color.orange.opacity(0.08)
        case .error:
            Color.red.opacity(0.08)
        }
    }

    private var strokeColor: Color {
        switch kind {
        case .warning:
            Color.orange.opacity(0.2)
        case .error:
            Color.red.opacity(0.22)
        }
    }
}
