import SwiftUI

/// LabeledContent avec un lien cliquable en trailing.
/// Gère automatiquement http, mailto: et tel:
struct LabeledLink: View {
    let label: String
    let rawValue: String
    let scheme: Scheme

    enum Scheme {
        case web    // http/https — ajoute https:// si absent
        case mail   // mailto:
        case phone  // tel: — filtre les caractères non numériques
    }

    private var url: URL? {
        switch scheme {
        case .web:
            let s = rawValue.hasPrefix("http") ? rawValue : "https://\(rawValue)"
            return URL(string: s)
        case .mail:
            return URL(string: "mailto:\(rawValue)")
        case .phone:
            let digits = rawValue.filter { $0.isNumber || $0 == "+" }
            return URL(string: "tel:\(digits)")
        }
    }

    var body: some View {
        LabeledContent(label) {
            if let url {
                Link(rawValue, destination: url)
                    .foregroundStyle(.tint)
            } else {
                Text(rawValue)
            }
        }
    }
}
