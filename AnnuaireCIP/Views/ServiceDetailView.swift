import SwiftUI

struct ServiceDetailView: View {
    let service: DIService

    var body: some View {
        List {
            // Description
            Section("Description") {
                Text(service.description)
                    .font(.body)
            }

            // Thématiques & type
            if service.type != nil || !(service.thematiques ?? []).isEmpty {
                Section("Catégorie") {
                    if let type_ = service.type {
                        LabeledContent("Type", value: type_)
                    }
                    if let thematiques = service.thematiques, !thematiques.isEmpty {
                        TagsView(label: "Thématiques", tags: thematiques)
                    }
                }
            }

            // Publics
            if service.publics != nil || service.publicsPrecisions != nil || service.conditionsAcces != nil {
                Section("Public visé") {
                    if let publics = service.publics, !publics.isEmpty {
                        TagsView(label: "Publics", tags: publics)
                    }
                    if let precisions = service.publicsPrecisions {
                        LabeledContent("Précisions", value: precisions)
                    }
                    if let conditions = service.conditionsAcces {
                        LabeledContent("Conditions d'accès", value: conditions)
                    }
                }
            }

            // Frais
            if service.frais != nil || service.fraisPrecisions != nil {
                Section("Frais") {
                    if let frais = service.frais {
                        LabeledContent("Tarif", value: frais)
                    }
                    if let precisions = service.fraisPrecisions {
                        LabeledContent("Précisions", value: precisions)
                    }
                }
            }

            // Accueil & localisation
            Section("Accueil") {
                if let modes = service.modesAccueil, !modes.isEmpty {
                    TagsView(label: "Modes d'accueil", tags: modes)
                }
                if !service.addressLine.isEmpty {
                    LabeledContent("Adresse", value: service.addressLine)
                }
                if let zones = service.zoneEligibilite, !zones.isEmpty {
                    TagsView(label: "Zone d'éligibilité", tags: zones)
                }
            }

            // Contact
            if service.telephone != nil || service.courriel != nil || service.contactNomPrenom != nil {
                Section("Contact") {
                    if let contact = service.contactNomPrenom {
                        LabeledContent("Nom", value: contact)
                    }
                    if let tel = service.telephone {
                        LabeledContent("Téléphone", value: tel)
                    }
                    if let email = service.courriel {
                        LabeledContent("Email", value: email)
                    }
                }
            }

            // Mobilisation
            if service.modesMobilisation != nil || service.mobilisablePar != nil || service.lienMobilisation != nil {
                Section("Mobilisation") {
                    if let modes = service.modesMobilisation, !modes.isEmpty {
                        TagsView(label: "Modes", tags: modes)
                    }
                    if let par = service.mobilisablePar, !par.isEmpty {
                        TagsView(label: "Mobilisable par", tags: par)
                    }
                    if let precisions = service.mobilisationPrecisions {
                        Text(precisions).font(.body)
                    }
                    if let lien = service.lienMobilisation {
                        LabeledContent("Lien", value: lien)
                    }
                }
            }

            // Identification
            Section("Identification") {
                LabeledContent("Source", value: service.source)
                LabeledContent("Mise à jour", value: service.dateMajFormatted)
                if let lien = service.lienSource {
                    LabeledContent("Lien source", value: lien)
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(service.nom)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Tags

private struct TagsView: View {
    let label: String
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            FlowLayout(tags: tags)
        }
        .padding(.vertical, 2)
    }
}

private struct FlowLayout: View {
    let tags: [String]

    var body: some View {
        // Utilise un simple VStack de lignes wrappées via ViewThatFits
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), alignment: .leading)], spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.tint.opacity(0.12), in: Capsule())
                    .foregroundStyle(.tint)
            }
        }
    }
}
