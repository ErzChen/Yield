import CoreLocation
import Observation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    var coordinate: CLLocationCoordinate2D? = nil
    var status: CLAuthorizationStatus = .notDetermined
    
    @ObservationIgnored private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        status = manager.authorizationStatus
        #if DEBUG
        if let mock = Debug.mockCoordinate {
            coordinate = mock
            status = Debug.mockStatus
        }
        #endif
    }
    
    private var isMocked: Bool {
        #if DEBUG
        return Debug.mockCoordinate != nil
        #else
        return false
        #endif
    }
    
    func start() {
        guard !isMocked else { return }
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }
    
    // Delegate methods
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard !isMocked else { return }
        status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !isMocked else { return }
        if let latest = locations.last {
            coordinate = latest.coordinate
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("location error:", error)
    }
}
