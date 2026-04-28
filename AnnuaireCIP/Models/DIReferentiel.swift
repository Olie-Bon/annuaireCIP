import Foundation

struct DIReferentielItem: Codable, Identifiable {
    let value: String
    let label: String
    let description: String?

    var id: String { value }
}
