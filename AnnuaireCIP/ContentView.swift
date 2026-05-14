//
//  ContentView.swift
//  AnnuaireCIP
//
//  Created by Olie on 25/04/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var vm = AnnuaireViewModel()
    @State private var parcoursVM = ParcoursViewModel()

    var body: some View {
        TabView {
            StructuresTab(vm: vm)
                .tabItem { Label("Structures", systemImage: "building.2") }

            ServicesTab(vm: vm)
                .tabItem { Label("Services", systemImage: "hands.and.sparkles") }

            NavigationStack {
                CombinedMapView(vm: vm)
            }
            .tabItem { Label("Carte", systemImage: "map") }

            FreinsView(parcoursVM: parcoursVM, annuaireVM: vm)
                .tabItem { Label("Parcours", systemImage: "figure.walk") }
        }
        .task { await vm.load() }
    }
}

// MARK: - Structures tab

private struct StructuresTab: View {
    let vm: AnnuaireViewModel
    @State private var query = ""
    @State private var showFiltres = false

    private var filtered: [DIStructure] { vm.filteredStructures(query: query) }
    private var isFiltered: Bool { !query.isEmpty || vm.hasActiveStructureFilters }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Chargement…")
                } else if let error = vm.errorMessage {
                    ContentUnavailableView {
                        Label("Erreur de chargement", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Réessayer") { Task { await vm.load() } }
                            .buttonStyle(.borderedProminent)
                    }
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    List {
                        if isFiltered {
                            Text("\(filtered.count) résultat\(filtered.count > 1 ? "s" : "") sur \(vm.structures.count)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .listRowBackground(Color.clear)
                        }
                        ForEach(filtered) { structure in
                            NavigationLink(destination: StructureDetailView(
                                structure: structure,
                                services: vm.services.filter { $0.structureId == structure.id }
                            )) {
                                StructureRow(structure: structure)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Structures (\(vm.structures.count))")
            .searchable(text: $query, prompt: "Nom, commune, description…")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showFiltres.toggle() } label: {
                        Image(systemName: vm.hasActiveStructureFilters
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .inspector(isPresented: $showFiltres) {
                FiltresView(vm: vm, mode: .structures)
                    .inspectorColumnWidth(min: 260, ideal: 300, max: 360)
            }
        }
    }
}

// MARK: - Services tab

private struct ServicesTab: View {
    let vm: AnnuaireViewModel
    @State private var query = ""
    @State private var showFiltres = false

    private var filtered: [DIService] { vm.filteredServices(query: query) }
    private var isFiltered: Bool { !query.isEmpty || vm.hasActiveFilters }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Chargement…")
                } else if let error = vm.errorMessage {
                    ContentUnavailableView {
                        Label("Erreur de chargement", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Réessayer") { Task { await vm.load() } }
                            .buttonStyle(.borderedProminent)
                    }
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    List {
                        if isFiltered {
                            Text("\(filtered.count) résultat\(filtered.count > 1 ? "s" : "") sur \(vm.services.count)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .listRowBackground(Color.clear)
                        }
                        ForEach(filtered) { service in
                            NavigationLink(destination: ServiceDetailView(service: service)) {
                                ServiceRow(service: service)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Services (\(vm.services.count))")
            .searchable(text: $query, prompt: "Nom, type, thématique, commune…")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showFiltres.toggle() } label: {
                        Image(systemName: vm.hasActiveFilters
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .inspector(isPresented: $showFiltres) {
                FiltresView(vm: vm, mode: .services)
                    .inspectorColumnWidth(min: 260, ideal: 300, max: 360)
            }
        }
    }
}

// MARK: - Rows

private struct StructureRow: View {
    let structure: DIStructure

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(structure.nom)
                    .font(.headline)
                if !structure.addressLine.isEmpty {
                    Text(structure.addressLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let tel = structure.telephone {
                    Text(tel)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            if let score = structure.scoreQualite {
                ScoreQualiteView(score: score)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ServiceRow: View {
    let service: DIService

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(service.nom)
                    .font(.headline)
                if let type_ = service.type {
                    Text(type_)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !service.addressLine.isEmpty {
                    Text(service.addressLine)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            if let score = service.scoreQualite {
                ScoreQualiteView(score: score)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
