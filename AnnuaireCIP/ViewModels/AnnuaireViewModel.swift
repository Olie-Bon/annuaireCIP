import Foundation

@Observable
final class AnnuaireViewModel {
    var structures: [DIStructure] = []
    var services: [DIService] = []
    var isLoading = false
    var errorMessage: String?

    func load(codeDepartement: String = "13") async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let fetchedStructures = NetworkService.shared.fetchStructures(codeDepartement: codeDepartement)
            async let fetchedServices   = NetworkService.shared.fetchServices(codeDepartement: codeDepartement)
            (structures, services) = try await (fetchedStructures, fetchedServices)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
