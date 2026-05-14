import CoreLocation
import Observation

@Observable
final class ParcoursViewModel {
    var adresse: String = ""
    var coordonnees: CLLocationCoordinate2D?
    var communeGeocodee: String?
    var isGeocoding = false
    var geocodingError: String?

    private let geocoder = CLGeocoder()

    var aCoordonnees: Bool { coordonnees != nil }

    var labelRecherche: String {
        if let commune = communeGeocodee {
            return "Services près de \(commune)"
        }
        return "Services data·inclusion (dept. 13)"
    }

    var iconRecherche: String {
        aCoordonnees ? "location.magnifyingglass" : "magnifyingglass"
    }

    func geocoderAdresse() async {
        let input = adresse.trimmingCharacters(in: .whitespaces)
        guard !input.isEmpty else { return }
        isGeocoding = true
        geocodingError = nil
        coordonnees = nil
        communeGeocodee = nil
        defer { isGeocoding = false }
        do {
            let placemarks: [CLPlacemark] = try await withCheckedThrowingContinuation { continuation in
                geocoder.geocodeAddressString(input) { placemarks, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: placemarks ?? [])
                    }
                }
            }
            if let placemark = placemarks.first, let coord = placemark.location?.coordinate {
                coordonnees = coord
                communeGeocodee = placemark.locality ?? placemark.administrativeArea
            } else {
                geocodingError = "Adresse introuvable"
            }
        } catch {
            geocodingError = "Adresse introuvable"
        }
    }

    func reset() {
        geocoder.cancelGeocode()
        adresse = ""
        coordonnees = nil
        communeGeocodee = nil
        geocodingError = nil
    }
}
