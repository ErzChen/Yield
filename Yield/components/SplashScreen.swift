import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()
            VStack(spacing: 0) {
                Image("basket")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                Text("Yield")
                    .font(Font.besleyBold(Font.splashTitle))
                    .foregroundStyle(Color.accent)
                    
            }
        }
    }
    
}

#Preview {
    SplashScreen()
}
