import CoreLocation

#if DEBUG
enum Debug {
    static let mockCoordinate: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 43.5448, longitude: -80.2482)
    static let mockStatus: CLAuthorizationStatus = .authorizedWhenInUse
}
#endif
