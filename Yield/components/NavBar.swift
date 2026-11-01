import SwiftUI

struct NavBar: View {
    @Binding var currentTab: String
    @State private var logMenuOpened = false
    @State private var logItemsVisible = false

    private let buttonSize: CGFloat = 64

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            slot("calendar", "Today", "square.and.pencil", "Entry")
            slot("chart.xyaxis.line", "Insights", "map", "Spots")
            logButton
            slot("text.book.closed", "Library", "camera", "Photo")
            slot("person.crop.circle", "You", "figure.walk", "Trip")
        }
        .padding(.top, 8)
        .background {
            ZStack(alignment: .topLeading) {
                Color.surface
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.accent)
                        .frame(width: buttonSize, height: buttonSize)
                        .scaleEffect(logMenuOpened ? 7 : 1)
                    Spacer()
                }
                .padding(.top, 8)
            }
            .clipped()
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func slot(_ tabSymbol: String, _ tabTitle: String, _ actionSymbol: String, _ actionTitle: String) -> some View {
        ZStack {
            tabButton(tabSymbol, tabTitle)
                .opacity(logMenuOpened ? 0 : 1)
                .allowsHitTesting(!logMenuOpened)
                .animation(
                    logMenuOpened ? .easeOut(duration: 0.15) : .easeIn(duration: 0.2).delay(0.25),
                    value: logMenuOpened
                )

            menuButton(actionSymbol, actionTitle)
                .opacity(logItemsVisible ? 1 : 0)
                .allowsHitTesting(logItemsVisible)
        }
        .frame(maxWidth: .infinity)
    }

    private func tabButton(_ symbol: String, _ title: String) -> some View {
        let isSelected = currentTab == title
        return Button {
            currentTab = title
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .symbolVariant(isSelected ? .fill : .none)
                    .font(.system(size: 22))
                    .frame(height: 28)
                Text(title)
                    .font(Font.manropeBold(Font.text))
            }
            .foregroundStyle(isSelected ? Color.accent : Color.textSecondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }

    private func menuButton(_ symbol: String, _ title: String) -> some View {
        Button {
            toggleLogMenu()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 22))
                    .frame(height: 28)
                Text(title)
                    .font(Font.manropeBold(Font.text))
            }
            .foregroundStyle(Color.surface)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }

    private var logButton: some View {
        Button(action: toggleLogMenu) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .semibold))
                .rotationEffect(.degrees(logMenuOpened ? 135 : 0))
                .animation(.linear(duration: 0.2), value: logMenuOpened)
                .foregroundStyle(Color.surface)
                .frame(width: buttonSize, height: buttonSize)
                .background(Circle().fill(Color.accent))
                .overlay(Circle().stroke(Color.surface, lineWidth: 4))
                .shadow(color: Color.Palette.darkBrown.opacity(logMenuOpened ? 0 : 0.5), radius: 4, y: 2)
        }
        .frame(maxWidth: .infinity)
    }

    private func toggleLogMenu() {
        if logMenuOpened {
            withAnimation(.easeOut(duration: 0.15)) { logItemsVisible = false }
            withAnimation(.spring(duration: 0.4, bounce: 0).delay(0.1)) { logMenuOpened = false }
        } else {
            withAnimation(.spring(duration: 0.45, bounce: 0)) { logMenuOpened = true }
            withAnimation(.easeIn(duration: 0.2).delay(0.3)) { logItemsVisible = true }
        }
    }
}

#Preview {
    @Previewable @State var selectedTab: String = "Today"
    VStack {
        Spacer()
        NavBar(currentTab: $selectedTab)
    }
    .background(Color.background)
}
