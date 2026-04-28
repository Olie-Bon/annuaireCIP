import Foundation

@Observable
final class AnnuaireViewModel {
    var structures: [DIStructure] = []
    var services: [DIService] = []
    var isLoading = false
    var errorMessage: String?

    // Referentials
    var thematiques: [DIReferentielItem] = []
    var publics: [DIReferentielItem] = []
    var modesAccueil: [DIReferentielItem] = []
    var typesServices: [DIReferentielItem] = []
    var frais: [DIReferentielItem] = []

    // Active filters — services
    var selectedThematiques: Set<String> = []
    var selectedPublics: Set<String> = []
    var selectedModesAccueil: Set<String> = []
    var selectedTypesServices: Set<String> = []
    var selectedFrais: Set<String> = []

    // Active filters — structures
    var selectedSources: Set<String> = []

    var hasActiveFilters: Bool {
        !selectedThematiques.isEmpty || !selectedPublics.isEmpty ||
        !selectedModesAccueil.isEmpty || !selectedTypesServices.isEmpty ||
        !selectedFrais.isEmpty
    }

    var hasActiveStructureFilters: Bool { !selectedSources.isEmpty }

    func resetFilters() {
        selectedThematiques = []
        selectedPublics = []
        selectedModesAccueil = []
        selectedTypesServices = []
        selectedFrais = []
    }

    func resetStructureFilters() { selectedSources = [] }

    func filteredServices(query: String = "") -> [DIService] {
        var result = services

        if !query.isEmpty {
            result = result.filter {
                $0.nom.localizedCaseInsensitiveContains(query) ||
                $0.description.localizedCaseInsensitiveContains(query) ||
                ($0.commune?.localizedCaseInsensitiveContains(query) ?? false) ||
                ($0.type?.localizedCaseInsensitiveContains(query) ?? false) ||
                ($0.thematiques?.contains { $0.localizedCaseInsensitiveContains(query) } ?? false)
            }
        }
        if !selectedThematiques.isEmpty {
            // selectedThematiques holds parent prefixes (e.g. "acces-droits").
            // Match any service thematique equal to the prefix OR starting with "prefix--".
            result = result.filter { service in
                (service.thematiques ?? []).contains { thematique in
                    selectedThematiques.contains { prefix in
                        thematique == prefix || thematique.hasPrefix(prefix + "--")
                    }
                }
            }
        }
        if !selectedPublics.isEmpty {
            result = result.filter {
                ($0.publics ?? []).contains { selectedPublics.contains($0) }
            }
        }
        if !selectedModesAccueil.isEmpty {
            result = result.filter {
                ($0.modesAccueil ?? []).contains { selectedModesAccueil.contains($0) }
            }
        }
        if !selectedTypesServices.isEmpty {
            result = result.filter {
                $0.type.map { selectedTypesServices.contains($0) } ?? false
            }
        }
        if !selectedFrais.isEmpty {
            result = result.filter {
                $0.frais.map { selectedFrais.contains($0) } ?? false
            }
        }
        return result.sorted {
            ($0.scoreQualite ?? -1) > ($1.scoreQualite ?? -1)
        }
    }

    func filteredStructures(query: String = "") -> [DIStructure] {
        var result = structures
        if !query.isEmpty {
            result = result.filter {
                $0.nom.localizedCaseInsensitiveContains(query) ||
                ($0.commune?.localizedCaseInsensitiveContains(query) ?? false) ||
                ($0.description?.localizedCaseInsensitiveContains(query) ?? false)
            }
        }
        if !selectedSources.isEmpty {
            result = result.filter { selectedSources.contains($0.source) }
        }
        return result.sorted {
            ($0.scoreQualite ?? -1) > ($1.scoreQualite ?? -1)
        }
    }

    func load(codeDepartement: String = "13") async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let fetchedStructures   = NetworkService.shared.fetchStructures(codeDepartement: codeDepartement)
            async let fetchedServices     = NetworkService.shared.fetchServices(codeDepartement: codeDepartement)
            async let fetchedThematiques  = NetworkService.shared.fetchThematiques()
            async let fetchedPublics      = NetworkService.shared.fetchPublics()
            async let fetchedModesAccueil = NetworkService.shared.fetchModesAccueil()
            async let fetchedTypes        = NetworkService.shared.fetchTypesServices()
            async let fetchedFrais        = NetworkService.shared.fetchFrais()

            (structures, services) = try await (fetchedStructures, fetchedServices)

            // Referentials are non-critical: a failed route leaves the array empty
            thematiques  = (try? await fetchedThematiques)  ?? []
            publics      = (try? await fetchedPublics)      ?? []
            modesAccueil = (try? await fetchedModesAccueil) ?? []
            typesServices = (try? await fetchedTypes)       ?? []
            frais        = (try? await fetchedFrais)        ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
