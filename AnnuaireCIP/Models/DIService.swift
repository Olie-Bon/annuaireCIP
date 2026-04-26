import Foundation
import CoreLocation

struct DIService: Codable, Identifiable {
    let source: String
    let structureId: String
    let id: String
    let nom: String
    let description: String
    let lienSource: String?
    let dateMaj: String
    let type: String?
    let thematiques: [String]?
    let frais: String?
    let fraisPrecisions: String?
    let publics: [String]?
    let publicsPrecisions: String?
    let conditionsAcces: String?
    let commune: String?
    let codePostal: String?
    let codeInsee: String?
    let adresse: String?
    let complementAdresse: String?
    let longitude: Double?
    let latitude: Double?
    let telephone: String?
    let courriel: String?
    let modesAccueil: [String]?
    let zoneEligibilite: [String]?
    let contactNomPrenom: String?
    let lienMobilisation: String?
    let modesMobilisation: [String]?
    let mobilisablePar: [String]?
    let mobilisationPrecisions: String?

    enum CodingKeys: String, CodingKey {
        case source
        case structureId = "structure_id"
        case id, nom, description
        case lienSource = "lien_source"
        case dateMaj = "date_maj"
        case type, thematiques, frais
        case fraisPrecisions = "frais_precisions"
        case publics
        case publicsPrecisions = "publics_precisions"
        case conditionsAcces = "conditions_acces"
        case commune
        case codePostal = "code_postal"
        case codeInsee = "code_insee"
        case adresse
        case complementAdresse = "complement_adresse"
        case longitude, latitude, telephone, courriel
        case modesAccueil = "modes_accueil"
        case zoneEligibilite = "zone_eligibilite"
        case contactNomPrenom = "contact_nom_prenom"
        case lienMobilisation = "lien_mobilisation"
        case modesMobilisation = "modes_mobilisation"
        case mobilisablePar = "mobilisable_par"
        case mobilisationPrecisions = "mobilisation_precisions"
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
