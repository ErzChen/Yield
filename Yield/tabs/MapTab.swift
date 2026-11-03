import SwiftUI
import MapKit

struct MapTab: View {
    @Environment(LocationManager.self) private var location
    @Environment(SpotStore.self) private var spots
    @State private var newName = ""
    @State private var pendingCoordinate: CLLocationCoordinate2D?
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedSpot: Spot?
    
    var body: some View {
        Map(position: $position) {
            UserAnnotation()
            ForEach(spots.spots) { spot in
                Annotation(spot.name, coordinate: spot.coordinate) {
                    Button {
                        pendingCoordinate = nil
                        withAnimation(.spring(duration: 0.35)) {
                            selectedSpot = spot
                        }
                    } label: {
                        Image(systemName: "mappin")
                            .font(.system(size: Size.mapPinSize, weight: .semibold))
                            .foregroundStyle(Color.surface)
                            .padding(Size.smallPadding)
                            .background(Circle().fill(Color.accent).strokeBorder(Color.surface, lineWidth: 2))
                            .appShadow()
                    }
                
                }
            }
            if let pending = pendingCoordinate {
                Annotation("New spot", coordinate: pending) {
                    Image(systemName: "mappin")
                        .font(.system(size: Size.mapPinSize, weight: .semibold))
                        .foregroundStyle(Color.surface)
                        .padding(Size.smallPadding)
                        .background(Circle().fill(Color.accent).strokeBorder(Color.surface, lineWidth: 2))
                        .appShadow()
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
                .backgroundStyle(Color.surface)
            MapCompass()
                .backgroundStyle(Color.surface)
        }
        .mapStyle(.imagery(elevation: .realistic))
        .overlay(alignment: .bottom) {
            if let spot = selectedSpot {
                SpotModal(spot: spot, onClose: closeSpot)
                    .id(spot.id)
                    .padding(Size.regPadding)
                    .transition(.move(edge: .bottom))
            } else if pendingCoordinate != nil {
                SaveSpotModal(
                    name: $newName,
                    onSave: {
                        Task {
                            await saveSpot()
                        }
                    },
                    onCancel: cancelPending
                )
                .padding(Size.regPadding)
                .transition(.move(edge: .bottom))
            } else {
                HStack(alignment: .bottom) {
                    Spacer()
                    Button(action: startPending) {
                        Image(systemName: "mappin")
                            .font(.system(size: Size.mapNavButtonSize, weight: .semibold))
                            .foregroundStyle(Color.surface)
                            .padding(Size.regPadding)
                            .background(Circle().fill(Color.accent).strokeBorder(Color.surface, lineWidth: 2))
                            .appShadow()
                            .padding(Size.largePadding)
                    }
                }
            }
        }
    }
    
    private func startPending() {
        guard let coordinate = location.coordinate else { return }
        newName = ""
        withAnimation(.spring(duration: 0.35)) {
            pendingCoordinate = coordinate
        }
    }

    private func cancelPending() {
        withAnimation(.spring(duration: 0.35)) {
            pendingCoordinate = nil
        }
        newName = ""
    }

    private func closeSpot() {
        withAnimation(.spring(duration: 0.35)) {
            selectedSpot = nil
        }
    }

    private func saveSpot() async {
        guard let coordinate = pendingCoordinate else { return }

        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Unnamed spot" : trimmed

        withAnimation(.spring(duration: 0.35)) {
            pendingCoordinate = nil
        }
        newName = ""

        await spots.add(name, coordinate)
    }
}

private struct Modal<Content: View, Footer: View>: View {
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
                    .fill(Color.surfaceAccent)
                    .frame(width: 60, height: 6)
                Spacer()
            }
            .padding(.vertical, Size.regPadding)
            .contentShape(Rectangle())
            .gesture(dismissGesture)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            footer
                .padding(.top, Size.regPadding)
                .padding(.bottom, Size.largePadding)
        }
        .padding(.horizontal, Size.largePadding)
        .frame(maxWidth: .infinity, maxHeight: 300, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(Color.surface)
        )
        .appShadow()
        .offset(y: dragOffset)
    }

    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                let closed = value.translation.height > 100
                    || value.predictedEndTranslation.height > 200

                if closed {
                    onClose()
                } else {
                    withAnimation(.spring(duration: 0.3)) {
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

private struct SpotModal: View {
    let spot: Spot
    let onClose: () -> Void

    var body: some View {
        Modal(onClose: onClose) {
            Text(spot.name)
                .font(Font.besleyBold(Font.spotTitle))
                .foregroundStyle(Color.textPrimary)
            Text(String(format: "%.4f, %.4f", spot.latitude, spot.longitude))
                .font(Font.manropeRegular(Font.spotText))
                .foregroundStyle(Color.textSecondary)
        }
    }
}

struct SaveSpotModal: View {
    @Binding var name: String
    let onSave: () -> Void
    let onCancel: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        Modal(onClose: onCancel) {
            Text("Pin this spot")
                .font(Font.besleyBold(Font.spotTitle))
                .foregroundStyle(Color.textPrimary)

            TextField("Name this spot", text: $name)
                .font(Font.manropeRegular(Font.spotText))
                .foregroundStyle(Color.textPrimary)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit(onSave)
                .padding(Size.regPadding)
                .background {
                    RoundedRectangle(cornerRadius: Radius.tile)
                        .fill(Color.background)
                        .strokeBorder(Color.border, lineWidth: 1)
                }
                .padding(.top, Size.smallPadding)
        } footer: {
            Button(action: onSave) {
                Text("Drop Pin")
                    .font(Font.manropeBold(Font.spotText))
                    .foregroundStyle(Color.surface)
                    .frame(maxWidth: .infinity)
                    .padding(Size.regPadding)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                            .fill(Color.accent)
                    }
            }
        }
        .onAppear { focused = true }
    }
}
