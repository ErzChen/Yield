import SwiftUI

struct InfoButton<Content: View>: View {
    let title: String
    let content: Content
    
    @State private var isShowing = false
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        Button {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                isShowing = true
            }
            isShowing = true
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: Size.iconInline))
                .foregroundStyle(Color.textSecondary)
        }
        .fullScreenCover(isPresented: $isShowing) {
            InfoCard(title: title) {
                content
            }
            .presentationBackground(.clear)
        }
    }
}

struct InfoCard<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            Color.overlay
                .ignoresSafeArea()
                .opacity(appeared ? 1 : 0)
                .onTapGesture(perform: close)
            
            VStack(alignment: .leading, spacing: Size.medium) {
                HStack {
                    Text(title)
                        .font(.besleyMedium(Font.title))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Button(action: close) {
                        Image(systemName: "xmark")
                            .font(.system(size: Size.iconInline, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                            .frame(width: Size.tapTarget, height: Size.tapTarget)
                    }
                }
                
                ViewThatFits(in: .vertical) {
                    entries
                    ScrollView {
                        entries
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .padding(Size.extraLarge)
            .frame(maxWidth: Size.infoCardMaxHeight)
            .bordered(Color.surface, Radius.card)
            .appShadow()
            .padding(Size.pagePadding)
            .scaleEffect(appeared ? 1 : 0.96)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(Motion.fade) {
                appeared = true
            }
        }
    }
    
    private var entries: some View {
        VStack(alignment: .leading, spacing: Size.extraLarge) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func close() {
        withAnimation(Motion.fastFade) {
            appeared = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(150))
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                dismiss()
            }
        }
    }
}

struct InfoEntry<Visual: View>: View {
    let title: String
    let text: String
    let visual: Visual
    
    @State private var isShowing = false
    
    init(_ title: String, _ text: String, @ViewBuilder visual: () -> Visual) {
        self.title = title
        self.text = text
        self.visual = visual()
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: Size.large) {
            visual
                .frame(width: Size.ringSize)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.besleyMedium(Font.body))
                    .foregroundStyle(Color.textPrimary)
                Text(text)
                    .font(.manropeRegular(Font.bodySmall))
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}
