import SwiftUI

extension Color {
    enum Palette {
        static let tan = Color(red: 234/255, green: 225/255, blue: 212/255)
        static let beige = Color(red: 247/255, green: 246/255, blue: 241/255)
        static let lightBrown = Color(red: 204/255, green: 165/255, blue: 121/255)
        static let brown = Color(red: 149/255, green: 91/255, blue: 48/255)
        static let darkBrown = Color(red: 72/255, green: 54/255, blue: 42/255)
        static let black = Color(red: 30/255, green: 21/255, blue: 14/255)
        static let green = Color(red: 48/255, green: 90/255, blue: 52/255)
        static let darkGreen = Color(red: 65/255, green: 81/255, blue: 54/255)
    }

    static let background = Palette.tan
    static let surface = Palette.beige
}

extension Font {
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
    
    enum Size {
        static let large: CGFloat = 48
        static let small: CGFloat = 12
    }
    
    static let splashTitle = Size.large
    static let text = Size.small
}
