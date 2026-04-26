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
                    LabeledContent("Téléphone", value: tel)
                }
                if let email = structure.courriel {
                    LabeledContent("Email", value: email)
                }
                if let web = structure.siteWeb {
                    LabeledContent("Site web", value: web)
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
                LabeledContent("Mise à jour", value: structure.dateMaj)
                if let score = structure.scoreQualite {
                    LabeledContent("Score qualité", value: String(format: "%.0f %%", score * 100))
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
        .listStyle(.insetGrouped)
        .navigationTitle(structure.nom)
        .navigationBarTitleDisplayMode(.inline)
    }
}
