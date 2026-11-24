import SwiftUI

struct Modal<Content: View, Footer: View>: View {
    let onClose: () -> Void
    let content: Content
    let footer: Footer

    @State private var dragOffset: CGFloat = 0

    init(
        onClose: @escaping () -> Void,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.onClose = onClose
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Capsule()
                    .fill(Color.handle)
                    .frame(width: Size.handleWidth, height: Size.extraSmall)
                Spacer()
            }
            .padding(.vertical, Size.medium)
            .contentShape(Rectangle())
            .gesture(dismissGesture)

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            footer
                .padding(.top, Size.medium)
                .padding(.bottom, Size.extraLarge)
        }
        .padding(.horizontal, Size.extraLarge)
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(Color.surface)
        )
        .frame(maxWidth: .infinity, maxHeight: 300, alignment: .bottom)
        .appShadow()
        .offset(y: dragOffset)
        .padding(Size.pagePadding)
        .transition(.move(edge: .bottom))
    }

    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged {
                value in
                
                dragOffset = max(0, value.translation.height)
            }
            .onEnded {
                value in
                
                let closed = value.translation.height > 100
                    || value.predictedEndTranslation.height > 200

                if closed {
                    onClose()
                } else {
                    withAnimation(Motion.panel) {
                        dragOffset = 0
                    }
                }
            }
    }
}


extension Modal where Footer == EmptyView {
    init(onClose: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.init(onClose: onClose, content: content, footer: { EmptyView() })
    }
}

struct DomainChips: View {
    @Binding var selected: Set<String>
    
    private let domains = [
        (id: "fungi", title: "Fungi"),
        (id: "plant", title: "Plants"),
        (id: "animal", title: "Animals"),
        (id: "fish", title: "Fish"),
    ]
    
    var body: some View {
        HStack(spacing: Size.small) {
            ForEach(domains, id: \.id) {
                domain in
                
                chip(domain.id, domain.title)
            }
        }
    }
    
    private func chip(_ id: String, _ title: String) -> some View {
        let isSelected = selected.contains(id)
        
        return Button {
            if isSelected {
                selected.remove(id)
            } else {
                selected.insert(id)
            }
        } label: {
            Text(title)
                .font(.manropeMedium(Font.bodySmall))
                .foregroundStyle(isSelected ? Color.surface : Color.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: Size.tapTarget)
                .bordered(isSelected ? Color.accent : Color.background, Radius.tile)
        }
    }
}

struct VisitCard: View {
    @Environment(SpotStore.self) private var store
    
    let visit: Visit
    
    var body: some View {
        let finds = store.finds(for: visit)
        
        HStack(alignment: .center, spacing: Size.small) {
            VStack(alignment: .leading, spacing: 2) {
                Text(finds.isEmpty
                     ? "Checked, nothing"
                     : finds.map { $0.speciesName }.joined(separator: ", ")
                )
                .lineLimit(1)
                .font(.besleyMedium(Font.body))
                .foregroundStyle(Color.textPrimary)
                .lineHeight(.normal)
                
                Text(visit.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.manropeRegular(Font.bodySmall))
                    .foregroundStyle(Color.textSecondary)
            }
            
            Spacer()
            
            if !finds.isEmpty {
                Text("\(finds.count)")
                    .font(.manropeRegular(Font.bodySmall))
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, Size.medium)
                    .padding(.vertical, Size.extraSmall)
                    .background {
                        Capsule().fill(Color.border)
                    }
            }
        }
        .padding(Size.small)
        .bordered(.background, Radius.tile)
    }
}

struct SpotModal: View {
    @Environment(SpotStore.self) private var store

    let spot: Spot
    let onClose: () -> Void
    let onLog: () -> Void
    let onOpenSpot: () -> Void

    var body: some View {
        let visits = store.visits(for: spot)

        Modal(onClose: onClose) {
            Text(spot.name)
                .font(.besleyBold(Font.title))
                .foregroundStyle(Color.textPrimary)
            Text(visits.isEmpty ? "No visits yet" : "\(visits.count) \(visits.count > 1 ? "visits" : "visit")")
                .font(.manropeRegular(Font.body))
                .foregroundStyle(Color.textSecondary)

            if !visits.isEmpty {
                VStack(spacing: Size.small) {
                    ForEach(visits.prefix(2)) {
                        visit in

                        VisitCard(visit: visit)
                    }
                }
                .padding(.top, Size.medium)
            }
        } footer: {
            HStack(spacing: Size.small) {
                Button(action: onOpenSpot) {
                    Text("Open spot")
                        .font(.manropeBold(Font.body))
                        .foregroundStyle(Color.surface)
                        .frame(maxWidth: .infinity)
                        .padding(Size.medium)
                        .background {
                            RoundedRectangle(cornerRadius: Radius.tile)
                                .fill(Color.accent)
                        }
                }
                
                Button(action: onLog) {
                    Text("Log")
                        .font(.manropeBold(Font.body))
                        .foregroundStyle(Color.surface)
                        .frame(width: Size.logButtonWidth)
                        .padding(Size.medium)
                        .background {
                            RoundedRectangle(cornerRadius: Radius.tile)
                                .fill(Color.textPrimary)
                        }
                }
            }
        }
    }
}

struct LogChoiceModal: View {
    let onFound: () -> Void
    let onNothing: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Modal(onClose: onCancel) {
            Text("Log a visit")
                .font(.besleyMedium(Font.title))
                .foregroundStyle(Color.textPrimary)
        } footer: {
            VStack(spacing: Size.small) {
                Button(action: onFound) {
                    Text("Found something")
                        .font(.manropeBold(Font.body))
                        .foregroundStyle(Color.surface)
                        .frame(maxWidth: .infinity)
                        .padding(Size.medium)
                        .background {
                            RoundedRectangle(cornerRadius: Radius.tile)
                                .fill(Color.accent)
                        }
                }
                
                Button(action: onNothing) {
                    Text("Checked, nothing")
                        .font(.manropeBold(Font.body))
                        .foregroundStyle(Color.surface)
                        .frame(maxWidth: .infinity)
                        .padding(Size.medium)
                        .background {
                            RoundedRectangle(cornerRadius: Radius.tile)
                                .fill(Color.textPrimary)
                        }
                }
            }
        }
    }
}

struct SaveSpotModal: View {
    @FocusState private var focused: Bool
    @State var name: String
    
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        Modal(onClose: onCancel) {
            Text("Pin this spot")
                .font(.besleyMedium(Font.title))
                .foregroundStyle(Color.textPrimary)

            TextField("Name this spot", text: $name)
                .font(.manropeRegular(Font.body))
                .foregroundStyle(Color.textPrimary)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit(onSave)
                .padding(Size.medium)
                .bordered(.background, Radius.tile)
                .padding(.top, Size.small)
        } footer: {
            Button(action: onSave) {
                Text("Drop Pin")
                    .font(.manropeBold(Font.body))
                    .foregroundStyle(Color.surface)
                    .frame(maxWidth: .infinity)
                    .padding(Size.medium)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.tile)
                            .fill(Color.accent)
                    }
            }
        }
        .onAppear { focused = true }
    }
}

struct CheckedNothingModal: View {
    @State private var selected: Set<String> = []
    
    let onSave: (Set<String>) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Modal(onClose: onCancel) {
            Text("Checked, nothing")
                .font(.besleyMedium(Font.title))
                .foregroundStyle(Color.textPrimary)
            Text("What were you looking for?")
                .font(.manropeRegular(Font.body))
                .foregroundStyle(Color.textSecondary)
            
            DomainChips(selected: $selected)
                .padding(.top, Size.medium)
        } footer: {
            Button {
                onSave(selected)
            } label: {
                Text("Save")
                    .font(.manropeBold(Font.body))
                    .foregroundStyle(Color.surface)
                    .frame(maxWidth: .infinity)
                    .padding(Size.medium)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.tile)
                            .fill(Color.accent)
                    }
            }
            .disabled(selected.isEmpty)
            .opacity(selected.isEmpty ? 0.4 : 1)
        }
    }
}
