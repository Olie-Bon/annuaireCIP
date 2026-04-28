import SwiftUI

struct FiltresView: View {
    enum Mode { case services, structures }

    @Bindable var vm: AnnuaireViewModel
    let mode: Mode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header avec actions
            let hasFilters = mode == .services ? vm.hasActiveFilters : vm.hasActiveStructureFilters
            HStack {
                Button("Réinitialiser") {
                    mode == .services ? vm.resetFilters() : vm.resetStructureFilters()
                }
                .font(.subheadline)
                .foregroundStyle(hasFilters ? .red : .secondary)
                .disabled(!hasFilters)

                Spacer()
                Text("Filtres").font(.headline)
                Spacer()

                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.bar)

            Divider()

            // Contenu scrollable
            if vm.isLoading {
                ProgressView("Chargement des filtres…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        switch mode {
                        case .services: servicesContent
                        case .structures: structuresContent
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
        }
    }

    // MARK: - Services content

    @ViewBuilder
    private var servicesContent: some View {
        let tItems = parentThematiques
        if !tItems.isEmpty {
            FilterSection("Thématiques") {
                ForEach(tItems) { item in
                    CheckRow(
                        label: item.label,
                        isOn: vm.selectedThematiques.contains(item.value)
                    ) { vm.selectedThematiques.toggle(item.value) }
                }
            }
        }

        let pItems = effectivePublics
        if !pItems.isEmpty {
            FilterSection("Publics") {
                ForEach(pItems) { item in
                    CheckRow(
                        label: item.label,
                        isOn: vm.selectedPublics.contains(item.value)
                    ) { vm.selectedPublics.toggle(item.value) }
                }
            }
        }

        let mItems = effectiveModesAccueil
        if !mItems.isEmpty {
            FilterSection("Modes d'accueil") {
                ForEach(mItems) { item in
                    ToggleRow(
                        label: item.label,
                        isOn: Binding(
                            get: { vm.selectedModesAccueil.contains(item.value) },
                            set: { vm.selectedModesAccueil.setMembership(item.value, $0) }
                        )
                    )
                }
            }
        }

        let typeItems = effectiveTypesServices
        if !typeItems.isEmpty {
            FilterSection("Types de services") {
                ForEach(typeItems) { item in
                    CheckRow(
                        label: item.label,
                        isOn: vm.selectedTypesServices.contains(item.value)
                    ) { vm.selectedTypesServices.toggle(item.value) }
                }
            }
        }

        let fraisItems = effectiveFrais
        FilterSection("Frais") {
            if fraisItems.isEmpty {
                ToggleRow(
                    label: "Gratuit seulement",
                    isOn: Binding(
                        get: { vm.selectedFrais.contains("gratuit") },
                        set: { vm.selectedFrais.setMembership("gratuit", $0) }
                    )
                )
            } else {
                ForEach(fraisItems) { item in
                    ToggleRow(
                        label: item.label,
                        isOn: Binding(
                            get: { vm.selectedFrais.contains(item.value) },
                            set: { vm.selectedFrais.setMembership(item.value, $0) }
                        )
                    )
                }
            }
        }
    }

    // MARK: - Structures content

    @ViewBuilder
    private var structuresContent: some View {
        let sources = Set(vm.structures.map { $0.source }).sorted()
        if !sources.isEmpty {
            FilterSection("Sources") {
                ForEach(sources, id: \.self) { source in
                    CheckRow(
                        label: source,
                        isOn: vm.selectedSources.contains(source)
                    ) { vm.selectedSources.toggle(source) }
                }
            }
        } else {
            Text("Aucun filtre disponible")
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 40)
        }
    }

    // MARK: - Data helpers

    private var parentThematiques: [DIReferentielItem] {
        let source: [DIReferentielItem] = vm.thematiques.isEmpty
            ? Set(vm.services.flatMap { $0.thematiques ?? [] }).sorted()
                .map { DIReferentielItem(value: $0, label: $0, description: nil) }
            : vm.thematiques
        return extractParents(from: source)
    }

    private var effectivePublics: [DIReferentielItem] {
        if !vm.publics.isEmpty { return vm.publics }
        return Set(vm.services.flatMap { $0.publics ?? [] }).sorted()
            .map { DIReferentielItem(value: $0, label: $0, description: nil) }
    }

    private var effectiveModesAccueil: [DIReferentielItem] {
        if !vm.modesAccueil.isEmpty { return vm.modesAccueil }
        return Set(vm.services.flatMap { $0.modesAccueil ?? [] }).sorted()
            .map { DIReferentielItem(value: $0, label: $0, description: nil) }
    }

    private var effectiveTypesServices: [DIReferentielItem] {
        if !vm.typesServices.isEmpty { return vm.typesServices }
        return Set(vm.services.compactMap { $0.type }).sorted()
            .map { DIReferentielItem(value: $0, label: $0, description: nil) }
    }

    private var effectiveFrais: [DIReferentielItem] {
        if !vm.frais.isEmpty { return vm.frais }
        return Set(vm.services.compactMap { $0.frais }).sorted()
            .map { DIReferentielItem(value: $0, label: $0, description: nil) }
    }

    private func extractParents(from items: [DIReferentielItem]) -> [DIReferentielItem] {
        var seen = Set<String>()
        var parents: [DIReferentielItem] = []
        for item in items {
            if let range = item.value.range(of: "--") {
                let prefix = String(item.value[..<range.lowerBound])
                if seen.insert(prefix).inserted {
                    let label = prefix.split(separator: "-")
                        .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                        .joined(separator: " ")
                    parents.append(DIReferentielItem(value: prefix, label: label, description: nil))
                }
            } else if seen.insert(item.value).inserted {
                parents.append(item)
            }
        }
        return parents.sorted { $0.label < $1.label }
    }
}

// MARK: - Section container

private struct FilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 6)
            VStack(spacing: 0) {
                content
            }
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Row types

private struct CheckRow: View {
    let label: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                if isOn { Image(systemName: "checkmark").foregroundStyle(.tint) }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        Divider().padding(.leading, 16)
    }
}

private struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(label, isOn: $isOn)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        Divider().padding(.leading, 16)
    }
}

private extension Set {
    mutating func toggle(_ element: Element) {
        if contains(element) { remove(element) } else { insert(element) }
    }

    mutating func setMembership(_ element: Element, _ isMember: Bool) {
        if isMember { insert(element) } else { remove(element) }
    }
}
