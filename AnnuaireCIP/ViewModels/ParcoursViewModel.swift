import CoreLocation
import Observation

// MARK: - Parcours entry

struct ParcoursEntry: Identifiable {
    let id: UUID
    let frein: Frein
    let services: [(service: DIService, distance: Double?)]

    init(frein: Frein, services: [(service: DIService, distance: Double?)] = []) {
        self.id = UUID()
        self.frein = frein
        self.services = services
    }
}

// MARK: - ViewModel

@Observable
final class ParcoursViewModel {
    var adresse: String = ""
    var coordonnees: CLLocationCoordinate2D?
    var communeGeocodee: String?
    var isGeocoding = false
    var geocodingError: String?

    var entries: [ParcoursEntry] = []

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

    // MARK: - Entries

    func ajouter(frein: Frein, services: [(service: DIService, distance: Double?)] = []) {
        let entry = ParcoursEntry(frein: frein, services: services)
        if let idx = entries.firstIndex(where: { $0.frein.id == frein.id }) {
            entries[idx] = entry
        } else {
            entries.append(entry)
        }
    }

    func supprimer(freinId: String) {
        entries.removeAll { $0.frein.id == freinId }
    }

    func contient(freinId: String) -> Bool {
        entries.contains { $0.frein.id == freinId }
    }

    func vider() {
        entries.removeAll()
    }

    // MARK: - Geocoding

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
