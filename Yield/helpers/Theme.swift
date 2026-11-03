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
    static let surfaceAccent: Color = Palette.brown.opacity(0.6)
    static let textPrimary: Color = Palette.darkBrown
    static let textSecondary: Color = Palette.darkBrown.opacity(0.6)
    static let accent: Color = Palette.darkGreen
    static let border: Color = Palette.lightBrown.opacity(0.35)
    static let success: Color = Palette.green
    static let failure: Color = Palette.red
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Size.smallPadding)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(Color.surface)
                    .strokeBorder(Color.border, lineWidth: 1)
                    .appShadow()
            }
            .padding(.horizontal, Size.regPadding)
    }
}

extension View {
    func appShadow() -> some View {
        shadow(color: Color.Palette.darkBrown.opacity(0.1), radius: 8, y: 3)
    }
    
    func cardStyle() -> some View {
        self.modifier(CardModifier())
    }
}

extension Font {
    static func besleyRegular(_ size: CGFloat) -> Font {
        .custom("Besley-Regular", size: size)
    }
    static func besleyMedium(_ size: CGFloat) -> Font {
        .custom("Besley-Medium", size: size)
    }
    static func besleyBold(_ size: CGFloat) -> Font {
        .custom("Besley-Bold", size: size)
    }
    static func manropeRegular(_ size: CGFloat) -> Font {
        .custom("Manrope-Regular", size: size)
    }
    static func manropeMedium(_ size: CGFloat) -> Font {
        .custom("Manrope-Medium", size: size)
    }
    static func manropeBold(_ size: CGFloat) -> Font {
        .custom("Manrope-Bold", size: size)
    }
    
    static let splashTitle: CGFloat = 48
    static let spotTitle: CGFloat = 24
    static let spotText: CGFloat = 16
    static let navText: CGFloat = 12
    static let conditionsLabel: CGFloat = 12
    static let conditionsValue: CGFloat = 14
}

enum Size {
    static let navButtonSize: CGFloat = 64
    static let mapPinSize: CGFloat = 14
    static let mapNavButtonSize: CGFloat = 24
    
    static let smallPadding: CGFloat = 8
    static let regPadding: CGFloat = 12
    static let largePadding: CGFloat = 20
    
    static let navButtonSpacing: CGFloat = 4
    static let smallSpacing: CGFloat = 6
}

enum Radius {
    static let card: CGFloat = 20
    static let tile: CGFloat = 12
}
