import Foundation

enum FreinsServiceError: Error, LocalizedError {
    case fileNotFound
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "freins.json introuvable dans le bundle."
        case .decodingError(let error):
            return "Erreur de décodage freins.json : \(error.localizedDescription)"
        }
    }
}

struct FreinsService {
    static func loadFreins() throws -> [Frein] {
        guard let url = Bundle.main.url(forResource: "freins", withExtension: "json") else {
            throw FreinsServiceError.fileNotFound
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Frein].self, from: data)
        } catch {
            throw FreinsServiceError.decodingError(error)
        }
    }
}
