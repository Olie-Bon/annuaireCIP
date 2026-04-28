import SwiftUI

struct StructureDetailView: View {
    let structure: DIStructure
    var services: [DIService] = []

    var body: some View {
        List {
            // Coordonnées
            Section("Coordonnées") {
                if !structure.addressLine.isEmpty {
                    LabeledContent("Adresse", value: structure.addressLine)
                }
                if let tel = structure.telephone {
                    LabeledLink(label: "Téléphone", rawValue: tel, scheme: .phone)
                }
                if let email = structure.courriel {
                    LabeledLink(label: "Email", rawValue: email, scheme: .mail)
                }
                if let web = structure.siteWeb {
                    LabeledLink(label: "Site web", rawValue: web, scheme: .web)
                }
            }

            // Infos
            if let desc = structure.description {
                Section("Description") {
                    Text(desc)
                        .font(.body)
                }
            }

            if let horaires = structure.horairesAccueil {
                Section("Horaires d'accueil") {
                    Text(horaires)
                        .font(.body)
                }
            }

            // Identification
            Section("Identification") {
                LabeledContent("Source", value: structure.source)
                if let siret = structure.siret {
                    LabeledContent("SIRET", value: siret)
                }
                LabeledContent("Mise à jour") {
                    HStack(spacing: 8) {
                        Text(structure.dateMajFormatted)
                        if let score = structure.scoreQualite {
                            ScoreQualiteView(score: score)
                        }
                    }
                }
            }

            // Accessibilité
            if let acces = structure.accessibiliteLieu {
                Section("Accessibilité") {
                    Text(acces)
                }
            }

            // Réseaux
            if let reseaux = structure.reseauxPorteurs, !reseaux.isEmpty {
                Section("Réseaux porteurs") {
                    ForEach(reseaux, id: \.self) { reseau in
                        Text(reseau)
                    }
                }
            }

            // Services associés
            if !services.isEmpty {
                Section("Services associés (\(services.count))") {
                    ForEach(services) { service in
                        NavigationLink(destination: ServiceDetailView(service: service)) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(service.nom)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    if let type_ = service.type {
                                        Text(type_)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            } icon: {
                                Image(systemName: "hands.and.sparkles.fill")
                                    .foregroundStyle(.orange)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(structure.nom)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
