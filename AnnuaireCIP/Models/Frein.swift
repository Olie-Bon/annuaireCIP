import Foundation

struct RessourceTerrain: Codable, Identifiable {
    let id: UUID
    let nom: String
    let description: String?
    let contact: String?
    let adresse: String?
    let siteWeb: String?
    let source: String

    enum CodingKeys: String, CodingKey {
        case id, nom, description, contact, adresse, source
        case siteWeb = "site_web"
    }
}

struct Frein: Codable, Identifiable {
    let id: String
    let titre: String
    let description: String
    let signauxReperage: [String]
    let thematiquesAPI: [String]
    let publicsAPI: [String]?
    let freinsAssocies: [String]
    let ressourcesTerrain: [RessourceTerrain]
    let notesCIP: String?

    enum CodingKeys: String, CodingKey {
        case id, titre, description
        case signauxReperage = "signaux_reperage"
        case thematiquesAPI = "thematiques_api"
        case publicsAPI = "publics_api"
        case freinsAssocies = "freins_associes"
        case ressourcesTerrain = "ressources_terrain"
        case notesCIP = "notes_cip"
    }
}
