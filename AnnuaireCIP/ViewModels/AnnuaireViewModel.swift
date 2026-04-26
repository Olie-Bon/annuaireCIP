import Foundation

@Observable
final class AnnuaireViewModel {
    var structures: [DIStructure] = []
    var services: [DIService] = []
    var isLoading = false
    var errorMessage: String?

    // TODO: remplacer MockDataService par NetworkService quand l'API est accessible
    func load(codeDepartement: String = "13") async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let fetchedStructures = MockDataService.shared.fetchStructures()
            async let fetchedServices   = MockDataService.shared.fetchServices()
            (structures, services) = try await (fetchedStructures, fetchedServices)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
