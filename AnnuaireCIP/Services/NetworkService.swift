import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case missingToken
    case httpError(statusCode: Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .missingToken:
            return "Token API manquant. Ajoutez DI_API_TOKEN dans les variables d'environnement du schéma Xcode."
        case .httpError(let code):
            return "Erreur HTTP \(code)"
        case .decodingError(let error):
            return "Erreur de décodage : \(error.localizedDescription)"
        }
    }
}

actor NetworkService {
    static let shared = NetworkService()

    private let baseURL = "https://api.data.inclusion.beta.gouv.fr"
    private let pageSize = 100

    private var urlSession: URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }

    private func makeRequest(path: String, queryItems: [URLQueryItem]) throws -> URLRequest {
        var components = URLComponents(string: baseURL + path)
        components?.queryItems = queryItems
        guard let url = components?.url else { throw NetworkError.invalidURL }
        guard let token = ProcessInfo.processInfo.environment["DI_API_TOKEN"], !token.isEmpty else {
            throw NetworkError.missingToken
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    // MARK: - Generic paginated fetch

    private func fetchAllPages<T: Decodable>(
        path: String,
        baseQueryItems: [URLQueryItem]
    ) async throws -> [T] {
        var results: [T] = []
        var page = 1

        while true {
            let queryItems = baseQueryItems + [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "size", value: "\(pageSize)")
            ]
            let request = try makeRequest(path: path, queryItems: queryItems)
            let (data, response) = try await urlSession.data(for: request)

            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw NetworkError.httpError(statusCode: http.statusCode)
            }

            let decoded: PagedResponse<T>
            do {
                decoded = try JSONDecoder().decode(PagedResponse<T>.self, from: data)
            } catch {
                throw NetworkError.decodingError(error)
            }

            results.append(contentsOf: decoded.items)

            let totalPages = Int(ceil(Double(decoded.total) / Double(pageSize)))
            if page >= totalPages { break }
            page += 1
        }

        return results
    }

    // MARK: - Public API

    func fetchStructures(codeDepartement: String = "13") async throws -> [DIStructure] {
        let queryItems = [URLQueryItem(name: "code_departement", value: codeDepartement)]
        return try await fetchAllPages(path: "/api/v1/structures", baseQueryItems: queryItems)
    }

    func fetchServices(codeDepartement: String = "13") async throws -> [DIService] {
        let queryItems = [URLQueryItem(name: "code_departement", value: codeDepartement)]
        return try await fetchAllPages(path: "/api/v1/services", baseQueryItems: queryItems)
    }

    func searchServices(
        lat: Double? = nil,
        lon: Double? = nil,
        codeCommune: String? = nil,
        thematiques: [String]? = nil,
        publics: [String]? = nil,
        types: [String]? = nil,
        modesAccueil: [String]? = nil,
        frais: [String]? = nil,
        scoreQualiteMinimum: Double? = 0.6,
        exclureDoublons: Bool = true
    ) async throws -> [DIService] {
        var queryItems: [URLQueryItem] = []
        if let lat { queryItems.append(URLQueryItem(name: "lat", value: String(lat))) }
        if let lon { queryItems.append(URLQueryItem(name: "lon", value: String(lon))) }
        if let codeCommune { queryItems.append(URLQueryItem(name: "code_commune", value: codeCommune)) }
        thematiques?.forEach { queryItems.append(URLQueryItem(name: "thematiques", value: $0)) }
        publics?.forEach { queryItems.append(URLQueryItem(name: "publics", value: $0)) }
        types?.forEach { queryItems.append(URLQueryItem(name: "types", value: $0)) }
        modesAccueil?.forEach { queryItems.append(URLQueryItem(name: "modes_accueil", value: $0)) }
        frais?.forEach { queryItems.append(URLQueryItem(name: "frais", value: $0)) }
        if let score = scoreQualiteMinimum {
            queryItems.append(URLQueryItem(name: "score_qualite_minimum", value: String(score)))
        }
        queryItems.append(URLQueryItem(name: "exclure_doublons", value: exclureDoublons ? "true" : "false"))
        let results: [SearchServiceResult] = try await fetchAllPages(
            path: "/api/v1/search/services",
            baseQueryItems: queryItems
        )
        return results.map(\.service)
    }

    // MARK: - Referentiels (direct arrays, not paginated)

    private func fetchReferentiel(path: String) async throws -> [DIReferentielItem] {
        let request = try makeRequest(path: path, queryItems: [])
        let (data, response) = try await urlSession.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw NetworkError.httpError(statusCode: http.statusCode)
        }
        do {
            return try JSONDecoder().decode([DIReferentielItem].self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    func fetchThematiques() async throws -> [DIReferentielItem] {
        try await fetchReferentiel(path: "/api/v1/doc/thematiques")
    }

    func fetchPublics() async throws -> [DIReferentielItem] {
        try await fetchReferentiel(path: "/api/v1/doc/publics")
    }

    func fetchModesAccueil() async throws -> [DIReferentielItem] {
        try await fetchReferentiel(path: "/api/v1/doc/modes-accueil")
    }

    func fetchTypesServices() async throws -> [DIReferentielItem] {
        try await fetchReferentiel(path: "/api/v1/doc/types")
    }

    func fetchFrais() async throws -> [DIReferentielItem] {
        try await fetchReferentiel(path: "/api/v1/doc/frais")
    }
}

// MARK: - Pagination envelope

struct PagedResponse<T: Decodable>: Decodable {
    let items: [T]
    let total: Int
}

struct SearchServiceResult: Decodable {
    let service: DIService
    let distance: Double?
}
