import SwiftUI

extension Color {
    enum Palette {
        static let tan: Color = Color(red: 234/255, green: 225/255, blue: 212/255)
        static let beige: Color = Color(red: 247/255, green: 246/255, blue: 241/255)
        static let lightBrown: Color = Color(red: 204/255, green: 165/255, blue: 121/255)
        static let brown: Color = Color(red: 149/255, green: 91/255, blue: 48/255)
        static let darkBrown: Color = Color(red: 72/255, green: 54/255, blue: 42/255)
        static let black: Color = Color(red: 30/255, green: 21/255, blue: 14/255)
        static let green: Color = Color(red: 48/255, green: 90/255, blue: 52/255)
        static let darkGreen: Color = Color(red: 65/255, green: 81/255, blue: 54/255)
        static let red: Color = Color(red: 168/255, green: 58/255, blue: 44/255)
    }
    
    static let background: Color = Palette.tan
    static let surface: Color = Palette.beige
    static let textPrimary: Color = Palette.darkBrown
    static let textSecondary: Color = Palette.darkBrown.opacity(0.6)
    static let accent: Color = Palette.green
    static let border: Color = Palette.lightBrown.opacity(0.35)
}

extension View {
    func appShadow() -> some View {
        shadow(color: Color.Palette.darkBrown.opacity(0.1), radius: 8, y: 3)
    }
}

extension Font {
    static func besleyRegular(size: CGFloat) -> Font {
        .custom("Besley-Regular", size: size)
    }
    static func besleyMedium(size: CGFloat) -> Font {
        .custom("Besley-Medium", size: size)
    }
    static func besleyBold(size: CGFloat) -> Font {
        .custom("Besley-Bold", size: size)
    }
    static func manropeRegular(size: CGFloat) -> Font {
        .custom("Manrope-Regular", size: size)
    }
    static func manropeMedium(size: CGFloat) -> Font {
        .custom("Manrope-Medium", size: size)
    }
    static func manropeBold(size: CGFloat) -> Font {
        .custom("Manrope-Bold", size: size)
    }
    
    static let splashTitle: CGFloat = 48
    static let text: CGFloat = 12
    static let label: CGFloat = 12
    static let display: CGFloat = 14
}

enum Radius {
    static let card: CGFloat = 20;
    static let tile: CGFloat = 12;
}
