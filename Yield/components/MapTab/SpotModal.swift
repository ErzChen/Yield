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

struct SpotModal: View {
    @Environment(SpotStore.self) private var store

    let spot: Spot
    let onClose: () -> Void
    let onAddSighting: () -> Void

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

                        visitCard(visit)
                    }
                }
                .padding(.top, Size.medium)
            }
        } footer: {
            Button(action: onAddSighting) {
                Text("Add Sighting")
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
    }
    
    private func visitCard(_ visit: Visit) -> some View {
        let finds = store.finds(for: visit)
        
        return HStack(alignment: .center, spacing: Size.small) {
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
        .padding(Size.small)
        .bordered(.background, Radius.tile)
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
