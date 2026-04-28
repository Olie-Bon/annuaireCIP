import SwiftUI

struct StructureDetailView: View {
    let structure: DIStructure

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
        }
        .listStyle(.inset)
        .navigationTitle(structure.nom)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
