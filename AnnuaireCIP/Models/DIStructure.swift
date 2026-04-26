import Foundation
import CoreLocation

struct DIStructure: Codable, Identifiable {
    let source: String
    let id: String
    let nom: String
    let dateMaj: String
    let description: String?
    let lienSource: String?
    let siret: String?
    let commune: String?
    let codePostal: String?
    let codeInsee: String?
    let adresse: String?
    let complementAdresse: String?
    let longitude: Double?
    let latitude: Double?
    let telephone: String?
    let courriel: String?
    let siteWeb: String?
    let horairesAccueil: String?
    let accessibiliteLieu: String?
    let reseauxPorteurs: [String]?
    let adresseCertifiee: Bool?
    let scoreQualite: Double?
    let doublons: [String]?

    enum CodingKeys: String, CodingKey {
        case source, id, nom
        case dateMaj = "date_maj"
        case description
        case lienSource = "lien_source"
        case siret, commune
        case codePostal = "code_postal"
        case codeInsee = "code_insee"
        case adresse
        case complementAdresse = "complement_adresse"
        case longitude, latitude, telephone, courriel
        case siteWeb = "site_web"
        case horairesAccueil = "horaires_accueil"
        case accessibiliteLieu = "accessibilite_lieu"
        case reseauxPorteurs = "reseaux_porteurs"
        case adresseCertifiee = "adresse_certifiee"
        case scoreQualite = "score_qualite"
        case doublons
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var addressLine: String {
        [adresse, codePostal, commune]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}
