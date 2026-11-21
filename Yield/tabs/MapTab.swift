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
            ForEach(spots.spots) {
                spot in
                
                Annotation(spot.name, coordinate: spot.coordinate) {
                    Button {
                        pendingCoordinate = nil
                        withAnimation(.spring(duration: 0.35)) {
                            selectedSpot = spot
                        }
                    } label: {
                        Pin
                            .frame(width: Size.tapTarget, height: Size.tapTarget)
                            .contentShape(Rectangle())
                    }
                
                }
            }
            if let pending = pendingCoordinate {
                Annotation("New spot", coordinate: pending) {
                    Pin
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
                    .padding(Size.pagePadding)
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
                .padding(Size.pagePadding)
                .transition(.move(edge: .bottom))
            } else {
                HStack(alignment: .bottom) {
                    Spacer()
                    Button(action: startPending) {
                        Image(systemName: "mappin")
                            .font(.system(size: Size.iconFeature, weight: .semibold))
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
    
    private var Pin: some View {
        Image(systemName: "mappin")
            .font(.system(size: Size.iconInline))
            .foregroundStyle(Color.surface)
            .padding(Size.smallPadding)
            .background(Circle().fill(Color.accent).strokeBorder(Color.surface, lineWidth: 2))
            .appShadow()
    }
    
    private func startPending() {
        guard let coordinate = location.coordinate else {
            return
        }
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
        guard let coordinate = pendingCoordinate else {
            return
        }

        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Unnamed spot" : trimmed

        withAnimation(.spring(duration: 0.35)) {
            pendingCoordinate = nil
        }
        newName = ""

        await spots.add(name, coordinate)
    }
}
