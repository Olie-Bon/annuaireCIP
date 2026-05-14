import SwiftUI

struct FreinsView: View {
    @State private var freins: [Frein] = []
    @State private var query = ""
    @State private var errorMessage: String?

    private var filtered: [Frein] {
        guard !query.isEmpty else { return freins }
        return freins.filter { $0.titre.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let error = errorMessage {
                    ContentUnavailableView {
                        Label("Impossible de charger les freins", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    }
                } else if filtered.isEmpty && !query.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    List(filtered) { frein in
                        NavigationLink(destination: FreinDetailView(frein: frein)) {
                            FreinRow(frein: frein)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Freins (\(freins.count))")
            .searchable(text: $query, prompt: "Rechercher un frein…")
        }
        .onAppear {
            do {
                freins = try FreinsService.loadFreins()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Row

private struct FreinRow: View {
    let frein: Frein

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(frein.titre)
                .font(.headline)
            Text(frein.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail

struct FreinDetailView: View {
    let frein: Frein
    @State private var servicesResultats: [DIService] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var showServices = false

    var body: some View {
        List {
            Section("Description") {
                Text(frein.description)
                    .font(.body)
            }

            if !frein.signauxReperage.isEmpty {
                Section("Signaux de repérage") {
                    ForEach(frein.signauxReperage, id: \.self) { signal in
                        Label(signal, systemImage: "smallcircle.filled.circle")
                            .font(.body)
                    }
                }
            }

            if !frein.freinsAssocies.isEmpty {
                Section("Freins associés") {
                    ForEach(frein.freinsAssocies, id: \.self) { id in
                        Label(id, systemImage: "link")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !frein.ressourcesTerrain.isEmpty {
                Section("Ressources terrain") {
                    ForEach(frein.ressourcesTerrain) { ressource in
                        RessourceTerrainRow(ressource: ressource)
                    }
                }
            }

            if let notes = frein.notesCIP {
                Section("Notes CIP") {
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                if isSearching {
                    HStack {
                        ProgressView()
                        Text("Recherche en cours…")
                            .foregroundStyle(.secondary)
                    }
                } else if let error = searchError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                } else if showServices {
                    if servicesResultats.isEmpty {
                        Text("Aucun service trouvé pour ces thématiques.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(servicesResultats) { service in
                            NavigationLink(destination: ServiceDetailView(service: service)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(service.nom).font(.headline)
                                    if let commune = service.commune {
                                        Text(commune).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Button {
                        Task { await searchServices() }
                    } label: {
                        Label("Voir les services data·inclusion", systemImage: "magnifyingglass")
                    }
                }
            } header: {
                Text("Services data·inclusion")
            }
        }
        .listStyle(.inset)
        .navigationTitle(frein.titre)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func searchServices() async {
        isSearching = true
        searchError = nil
        defer { isSearching = false }
        do {
            servicesResultats = try await NetworkService.shared.searchServices(
                codeCommune: "13055",
                thematiques: frein.thematiquesAPI.isEmpty ? nil : frein.thematiquesAPI
            )
            showServices = true
        } catch {
            searchError = error.localizedDescription
        }
    }
}

// MARK: - Ressource terrain row

private struct RessourceTerrainRow: View {
    let ressource: RessourceTerrain

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(ressource.nom)
                .font(.headline)
            if let description = ressource.description {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            if let adresse = ressource.adresse {
                Label(adresse, systemImage: "mappin")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            HStack(spacing: 12) {
                if let contact = ressource.contact {
                    LabeledLink(label: "Contact", rawValue: contact,
                                scheme: contact.contains("@") ? .mail : .phone)
                }
                if let site = ressource.siteWeb {
                    LabeledLink(label: "Site", rawValue: site, scheme: .web)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
