import SwiftUI

enum DockPillStyle {
    case mode(isActive: Bool)
    case utility(tint: Color)
}

struct DockPillView: View {
    let title: String
    let style: DockPillStyle
    var showsProgress = false

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .lineLimit(1)

            if showsProgress {
                ProgressView()
                    .tint(foregroundColor)
                    .controlSize(.small)
            }
        }
        .foregroundStyle(foregroundColor)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 74)
        .padding(.horizontal, 24)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(borderColor, lineWidth: 1.2)
        )
        .shadow(color: shadowColor, radius: 20, y: 8)
    }

    private var backgroundColor: Color {
        switch style {
        case let .mode(isActive):
            return isActive ? .polishPadTerracotta : .polishPadPaper
        case .utility:
            return .polishPadPaper.opacity(0.96)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case let .mode(isActive):
            return isActive ? Color.white : .polishPadNavy
        case let .utility(tint):
            return tint
        }
    }

    private var borderColor: Color {
        switch style {
        case let .mode(isActive):
            return isActive ? Color.polishPadTerracotta.opacity(0.72) : Color.polishPadStroke.opacity(0.72)
        case .utility:
            return Color.polishPadStroke.opacity(0.72)
        }
    }

    private var shadowColor: Color {
        switch style {
        case let .mode(isActive):
            return isActive ? Color.polishPadTerracotta.opacity(0.18) : Color.polishPadGlow.opacity(0.08)
        case .utility:
            return Color.polishPadGlow.opacity(0.06)
        }
    }
}
