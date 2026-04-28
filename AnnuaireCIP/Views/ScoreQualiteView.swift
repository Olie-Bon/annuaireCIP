import SwiftUI

/// Indicateur signal réseau — 4 barres verticales croissantes.
/// score : Double entre 0.0 et 1.0
struct ScoreQualiteView: View {
    let score: Double

    private var activeCount: Int {
        switch score {
        case ..<0.25:         return 1
        case 0.25..<0.50:    return 2
        case 0.50..<0.75:    return 3
        default:              return 4
        }
    }

    private var activeColor: Color {
        switch score {
        case ..<0.25:         return .red
        case 0.25..<0.50:    return .orange
        case 0.50..<0.75:    return .yellow
        default:              return .green
        }
    }

    private static let heights: [CGFloat] = [5, 8, 11, 14]

    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < activeCount ? activeColor : Color.secondary.opacity(0.25))
                        .frame(width: 4, height: Self.heights[i])
                }
            }
            Text("\(Int(score * 100)) %")
                .font(.caption2)
                .foregroundStyle(activeColor)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach([0.1, 0.3, 0.6, 0.9], id: \.self) { score in
            LabeledContent("Score \(Int(score * 100)) %") {
                ScoreQualiteView(score: score)
            }
        }
    }
    .padding()
}
