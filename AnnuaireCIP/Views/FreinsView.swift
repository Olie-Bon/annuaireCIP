import SwiftUI
import CoreLocation

// MARK: - FreinsView

struct FreinsView: View {
    let parcoursVM: ParcoursViewModel
    let annuaireVM: AnnuaireViewModel
    @State private var freins: [Frein] = []
    @State private var query = ""
    @State private var errorMessage: String?
    @State private var showExport = false

    private var filtered: [Frein] {
        guard !query.isEmpty else { return freins }
        return freins.filter { $0.titre.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AdresseBeneficiaireCard(vm: parcoursVM)
                }

                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                } else if filtered.isEmpty && !query.isEmpty {
                    Section {
                        Text("Aucun frein pour « \(query) »")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(filtered) { frein in
                        NavigationLink(destination: FreinDetailView(frein: frein, parcoursVM: parcoursVM, annuaireVM: annuaireVM)) {
                            FreinRow(frein: frein, inParcours: parcoursVM.contient(freinId: frein.id))
                        }
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle("Parcours")
            .searchable(text: $query, prompt: "Rechercher un frein…")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showExport = true } label: {
                        Label(
                            parcoursVM.entries.isEmpty ? "Exporter" : "Exporter (\(parcoursVM.entries.count))",
                            systemImage: "square.and.arrow.up"
                        )
                    }
                    .disabled(parcoursVM.entries.isEmpty)
                }
            }
            .sheet(isPresented: $showExport) {
                ParcoursExportSheet(vm: parcoursVM)
            }
        }
        .onAppear {
            guard freins.isEmpty else { return }
            do {
                freins = try FreinsService.loadFreins()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Adresse bénéficiaire

private struct AdresseBeneficiaireCard: View {
    @Bindable var vm: ParcoursViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Adresse du bénéficiaire", systemImage: "person.crop.circle")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField("12 rue des Oliviers, Marseille…", text: $vm.adresse)
                    .textFieldStyle(.plain)
                    .onSubmit { Task { await vm.geocoderAdresse() } }

                if vm.isGeocoding {
                    ProgressView().scaleEffect(0.8)
                } else if vm.aCoordonnees {
                    Button { vm.reset() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                } else if !vm.adresse.isEmpty {
                    Button { Task { await vm.geocoderAdresse() } } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(.tint)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let commune = vm.communeGeocodee {
                Label("Localisé : \(commune)", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else if let error = vm.geocodingError {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Frein row

private struct FreinRow: View {
    let frein: Frein
    var inParcours: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(frein.titre)
                    .font(.headline)
                Text(frein.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if inParcours {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Frein detail

struct FreinDetailView: View {
    let frein: Frein
    let parcoursVM: ParcoursViewModel
    let annuaireVM: AnnuaireViewModel
    @State private var servicesResultats: [(service: DIService, distance: Double?)] = []
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
                        ForEach(servicesResultats, id: \.service.id) { item in
                            NavigationLink(destination: ServiceDetailView(service: item.service)) {
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.service.nom).font(.headline)
                                        HStack(spacing: 8) {
                                            if let commune = item.service.commune {
                                                Text(commune).font(.caption).foregroundStyle(.secondary)
                                            }
                                            if let dist = item.distance {
                                                Text(distanceLabel(dist))
                                                    .font(.caption)
                                                    .foregroundStyle(.tertiary)
                                            }
                                        }
                                    }
                                    Spacer()
                                    let included = parcoursVM.contientService(freinId: frein.id, serviceId: item.service.id)
                                    Button {
                                        parcoursVM.toggleService(frein: frein, item: item)
                                    } label: {
                                        Image(systemName: included ? "minus.circle.fill" : "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(included ? Color.red : Color.accentColor)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                } else {
                    Button { searchServices() } label: {
                        Label(parcoursVM.labelRecherche, systemImage: parcoursVM.iconRecherche)
                    }
                    if !parcoursVM.aCoordonnees {
                        Text("Saisissez l'adresse du bénéficiaire dans Parcours pour des résultats géolocalisés.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            } header: {
                Text("Services data·inclusion")
            }

            Section {
                if parcoursVM.contient(freinId: frein.id) {
                    let n = parcoursVM.serviceCount(freinId: frein.id)
                    if n > 0 {
                        Label("\(n) service\(n > 1 ? "s" : "") inclus", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.tint)
                    }
                    Button(role: .destructive) {
                        parcoursVM.supprimer(freinId: frein.id)
                    } label: {
                        Label("Retirer du parcours", systemImage: "minus.circle")
                    }
                } else if showServices {
                    Text("Appuyez sur + pour ajouter des services à ce frein.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        parcoursVM.ajouter(frein: frein, services: [])
                    } label: {
                        Label("Ajouter ce frein au parcours", systemImage: "plus.circle")
                    }
                }
            } header: {
                Text("Parcours")
            }
        }
        .listStyle(.inset)
        .navigationTitle(frein.titre)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onChange(of: parcoursVM.coordonnees?.latitude) {
            showServices = false
            servicesResultats = []
        }
    }

    private func searchServices() {
        isSearching = true
        searchError = nil
        defer { isSearching = false }

        let thematiques = Set(frein.thematiquesAPI)
        let source = annuaireVM.services

        let filtered: [DIService] = thematiques.isEmpty ? source : source.filter { service in
            (service.thematiques ?? []).contains { thematique in
                thematiques.contains { prefix in
                    thematique == prefix || thematique.hasPrefix(prefix + "--")
                }
            }
        }

        if let coord = parcoursVM.coordonnees {
            let point = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            servicesResultats = filtered
                .compactMap { service -> (DIService, Double?)? in
                    guard let lat = service.latitude, let lon = service.longitude else { return nil }
                    let dist = point.distance(from: CLLocation(latitude: lat, longitude: lon))
                    return (service, dist)
                }
                .sorted { $0.1! < $1.1! }
        } else {
            servicesResultats = filtered
                .sorted { ($0.scoreQualite ?? -1) > ($1.scoreQualite ?? -1) }
                .map { ($0, nil) }
        }

        showServices = true
    }

    private func distanceLabel(_ metres: Double) -> String {
        metres < 1000
            ? "\(Int(metres)) m"
            : String(format: "%.1f km", metres / 1000)
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
