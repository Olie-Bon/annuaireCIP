import Foundation

actor MockDataService {
    static let shared = MockDataService()

    func fetchStructures() throws -> [DIStructure] {
        try loadBundle(file: "structures-marseille-dev", type: [DIStructure].self)
    }

    func fetchServices() throws -> [DIService] {
        try loadBundle(file: "services-marseille-dev", type: [DIService].self)
    }

    private func loadBundle<T: Decodable>(file: String, type: T.Type) throws -> T {
        guard let url = Bundle.main.url(forResource: file, withExtension: "json") else {
            throw MockError.fileNotFound(file)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

private enum MockError: Error, LocalizedError {
    case fileNotFound(String)
    var errorDescription: String? {
        if case .fileNotFound(let name) = self { return "Fichier introuvable : \(name).json" }
        return nil
    }
}
