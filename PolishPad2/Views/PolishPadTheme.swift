import SwiftUI

extension Color {
    static let ppBackground = Color(red: 0.975, green: 0.958, blue: 0.935)
    static let ppCanvas = Color(red: 1.000, green: 0.992, blue: 0.978)
    static let ppCard = Color(red: 1.000, green: 0.935, blue: 0.855)
    static let ppCardSoft = Color(red: 1.000, green: 0.972, blue: 0.935)
    static let ppAccent = Color(red: 0.760, green: 0.420, blue: 0.220)
    static let ppAccentSoft = Color(red: 0.960, green: 0.720, blue: 0.500)
    static let ppText = Color(red: 0.230, green: 0.125, blue: 0.075)
    static let ppSecondaryText = Color(red: 0.520, green: 0.450, blue: 0.390)
    static let ppToolbarText = Color(red: 0.610, green: 0.470, blue: 0.380)
    static let ppBorder = Color(red: 0.680, green: 0.560, blue: 0.450).opacity(0.28)
    static let ppWarmShadow = Color(red: 0.360, green: 0.210, blue: 0.120)
}

enum PolishPadLayout {
    static let outerCorner: CGFloat = 30
    static let cardCorner: CGFloat = 22
    static let toolbarCorner: CGFloat = 20
    static let horizontalSpacing: CGFloat = 18
    static let verticalSpacing: CGFloat = 18
}
