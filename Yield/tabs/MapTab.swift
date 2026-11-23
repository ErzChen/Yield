import SwiftUI
import MapKit

struct MapTab: View {
    @Environment(LocationManager.self) private var location
    @Environment(SpotStore.self) private var store
    @State private var newName = ""
    @State private var pendingCoordinate: CLLocationCoordinate2D?
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedSpot: Spot?
    @State private var addingTo: Spot?
    
    var body: some View {
        NavigationStack {
            mapView
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(item: $addingTo) {
                    spot in

                    AddSightingPage(spotName: spot.name) {
                        species, amount in

                        Task {
                            await store.addSighting(to: spot, species: species, amount: amount)
                        }
                    }
                }
        }
    }

    private var mapView: some View {
        Map(position: $position) {
            UserAnnotation()
            ForEach(store.spots) {
                spot in
                
                Annotation(spot.name, coordinate: spot.coordinate) {
                    Button {
                        pendingCoordinate = nil
                        withAnimation(Motion.panel) {
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
                SpotModal(spot: spot, onClose: closeSpot, onAddSighting: {
                    addingTo = spot
                })
                    .id(spot.id)
                    .padding(Size.pagePadding)
                    .transition(.move(edge: .bottom))
            } else if pendingCoordinate != nil {
                SaveSpotModal(
                    name: newName,
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
                            .padding(Size.medium)
                            .background(Circle().fill(Color.accent).strokeBorder(Color.surface, lineWidth: 2))
                            .appShadow()
                            .padding(Size.extraLarge)
                    }
                }
            }
        }
    }
    
    private var Pin: some View {
        Image(systemName: "mappin")
            .font(.system(size: Size.iconInline))
            .foregroundStyle(Color.surface)
            .padding(Size.small)
            .background(Circle().fill(Color.accent).strokeBorder(Color.surface, lineWidth: 2))
            .appShadow()
    }
    
    private func startPending() {
        guard let coordinate = location.coordinate else {
            return
        }
        newName = ""
        withAnimation(Motion.panel) {
            pendingCoordinate = coordinate
        }
    }

    private func cancelPending() {
        withAnimation(Motion.panel) {
            pendingCoordinate = nil
        }
        newName = ""
    }

    private func closeSpot() {
        withAnimation(Motion.panel) {
            selectedSpot = nil
        }
    }

    private func saveSpot() async {
        guard let coordinate = pendingCoordinate else {
            return
        }

        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Unnamed spot" : trimmed

        withAnimation(Motion.panel) {
            pendingCoordinate = nil
        }
        newName = ""

        await store.add(name, coordinate)
    }
}
