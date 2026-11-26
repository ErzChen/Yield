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
    @State private var logging: Spot?
    @State private var checkingNothing: Spot?
    @State private var openedSpot: Spot?
    
    var body: some View {
        NavigationStack {
            mapView
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(item: $addingTo) {
                    spot in

                    AddSightingPage(spotName: spot.name) {
                        species, amount in

                        Task {
                            await store.addVisit(
                                to: spot,
                                domains: species.domain,
                                finds: [NewFind(
                                    speciesId: species.id,
                                    speciesName: species.common_name,
                                    speciesDomain: species.domain,
                                    amount: amount
                                )]
                            )
                        }
                    }
                }
                .navigationDestination(item: $openedSpot) {
                    spot in
                    
                    SpotPage(spot: spot)
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
                SpotModal(
                    spot: spot,
                    onClose: closeSpot,
                    onLog: {
                        withAnimation(Motion.panel) {
                            selectedSpot = nil
                            logging = spot
                        }
                    },
                    onOpenSpot: {
                        openedSpot = spot
                    }
                )
                .id(spot.id)
            } else if let spot = logging {
                LogChoiceModal(
                    onFound: {
                        withAnimation(Motion.panel) {
                            logging = nil
                            addingTo = spot
                            selectedSpot = spot
                        }
                    },
                    onNothing: {
                        withAnimation(Motion.panel) {
                            logging = nil
                            checkingNothing = spot
                        }
                    },
                    onCancel: {
                        withAnimation(Motion.panel) {
                            logging = nil
                            selectedSpot = spot
                        }
                    }
                )
            } else if let spot = checkingNothing {
                CheckedNothingModal(
                    onSave: {
                        domains in
                        
                        Task {
                            await saveNothing(for: spot, domains: domains)
                        }
                    },
                    onCancel: cancelNothing
                )
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
    
    private func cancelNothing() {
        withAnimation(Motion.panel) {
            checkingNothing = nil
        }
    }
    
    private func saveNothing(for spot: Spot, domains: Set<String>) async {
        withAnimation(Motion.panel) {
            checkingNothing = nil
            selectedSpot = spot
        }
        
        await store.addVisit(to: spot, domains: domains.sorted().joined(separator: ","), finds: [])
    }
}
