@preconcurrency import CoreLocation
import Observation

// @Observable sans @MainActor au niveau de la classe — évite la propagation
// de l'inférence @MainActor aux types Decodable utilisés dans d'autres actors.
@Observable
final class LocationService: NSObject {
    private let manager = CLLocationManager()
    private(set) var coordinate: CLLocationCoordinate2D?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if isAuthorized(status) {
            manager.requestLocation()
        }
    }

    private func isAuthorized(_ status: CLAuthorizationStatus) -> Bool {
        if status == .authorizedAlways { return true }
        #if os(iOS) || os(watchOS) || os(tvOS)
        if status == .authorizedWhenInUse { return true }
        #endif
        return false
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.last?.coordinate else { return }
        DispatchQueue.main.async { self.coordinate = coord }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isAuthorized(manager.authorizationStatus) else { return }
        DispatchQueue.main.async { manager.requestLocation() }
    }
}
