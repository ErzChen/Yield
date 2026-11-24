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
    static let textSecondary: Color = Palette.darkBrown.opacity(0.78)
    static let accent: Color = Palette.darkGreen
    static let border: Color = Palette.lightBrown.opacity(0.35)
    static let success: Color = Palette.green
    static let failure: Color = Palette.red
    static let warning: Color = Palette.brown
    static let overlay: Color = Palette.black.opacity(0.5)
    static let overlayStrong: Color = Palette.black.opacity(0.75)
    static let shadowColor: Color = Palette.darkBrown.opacity(0.1)
    static let chartBar: Color = Palette.brown.opacity(0.6)
    static let handle: Color = Palette.brown.opacity(0.6)
    static let gridLine: Color = textSecondary.opacity(0.2)
    static let gridLineStrong: Color = textSecondary.opacity(0.5)
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Size.large)
            .frame(maxWidth: .infinity)
            .bordered(.surface, Radius.card)
            .padding(.horizontal, Size.large)
    }
}

struct BorderedModifier: ViewModifier {
    let fill: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius).strokeBorder(Color.border, lineWidth: 1)
            }
    }
}

extension View {
    func appShadow() -> some View {
        shadow(color: Color.shadowColor, radius: 8, y: 3)
    }
    
    func cardStyle() -> some View {
        self.modifier(CardModifier())
    }
    
    func bordered(_ fill: Color, _ radius: CGFloat) -> some View {
        modifier(BorderedModifier(fill: fill, radius: radius))
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
    
    static let caption: CGFloat = 11
    static let label: CGFloat = 12
    static let bodySmall: CGFloat = 14
    static let body: CGFloat = 16
    static let heading: CGFloat = 18
    static let subtitle: CGFloat = 20
    static let title: CGFloat = 24
    static let display: CGFloat = 28
    static let splash: CGFloat = 48
}

enum Size {
    // Icons
    static let iconInline: CGFloat = 16
    static let iconNav: CGFloat = 22
    static let iconFeature: CGFloat = 24
    static let tapTarget: CGFloat = 44
    
    // Nav Bar
    static let navButton: CGFloat = 64
    
    // Today Tab
    static let conditionsMinHeight: CGFloat = 80
    static let conditionsValueMinHeight: CGFloat = 32
    
    // Map Tab
    static let speciesThumb: CGFloat = 48
    static let stepperFieldWidth: CGFloat = 72
    static let logButtonWidth: CGFloat = 80
    
    // Library Tab
    static let domainHeight: CGFloat = 180
    static let detailImage: CGFloat = 260
    static let chart: CGFloat = 140
    static let lookalikeThumb: CGFloat = 72
    
    static let extraSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 20
    static let extraExtraLarge: CGFloat = 24
    
    static let pagePadding: CGFloat = large
    static let handleWidth: CGFloat = 56
    static let iconBox: CGFloat = 28
}

enum Motion {
    static let spring = Animation.spring(duration: 0.4, bounce: 0)
    static let fastFade = Animation.easeOut(duration: 0.15)
    static let fade = Animation.easeOut(duration: 0.2)
    static let panel = Animation.spring(duration: 0.35)
}

enum Radius {
    static let card: CGFloat = 20
    static let tile: CGFloat = 12
}
