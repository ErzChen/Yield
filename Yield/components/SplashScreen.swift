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
                    .font(.besleyMedium(Font.splash))
                    .foregroundStyle(Color.accent)
                    
            }
        }
    }
    
}

#Preview {
    SplashScreen()
}
