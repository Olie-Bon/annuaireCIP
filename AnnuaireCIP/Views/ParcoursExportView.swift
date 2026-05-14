import SwiftUI

// MARK: - Export sheet

struct ParcoursExportSheet: View {
    let vm: ParcoursViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var pdfURL: URL?
    @State private var isRendering = false

    var body: some View {
        NavigationStack {
            ScrollView {
                ParcoursDocumentView(vm: vm)
                    .padding(24)
            }
            .background(Color(white: 0.96))
            .navigationTitle("Parcours — \(vm.entries.count) frein\(vm.entries.count > 1 ? "s" : "")")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    exportButton
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) { vm.vider() } label: {
                        Label("Vider", systemImage: "trash")
                    }
                    .disabled(vm.entries.isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private var exportButton: some View {
        if isRendering {
            ProgressView()
        } else if let url = pdfURL {
            ShareLink(
                item: url,
                preview: SharePreview("Parcours.pdf", image: Image(systemName: "doc.richtext"))
            ) {
                Label("Partager", systemImage: "square.and.arrow.up")
            }
        } else {
            Button { Task { await renderPDF() } } label: {
                Label("Générer PDF", systemImage: "doc.badge.plus")
            }
        }
    }

    @MainActor
    private func renderPDF() async {
        isRendering = true
        defer { isRendering = false }

        let content = ParcoursDocumentView(vm: vm)
            .padding(32)
            .background(Color.white)
            .frame(width: 595)

        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = .init(width: 595, height: nil)
        renderer.scale = 1.0

        let mutableData = NSMutableData()
        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let consumer = CGDataConsumer(data: mutableData),
                  let ctx = CGContext(consumer: consumer, mediaBox: &box, nil)
            else { return }
            ctx.beginPDFPage(nil)
            draw(ctx)
            ctx.endPDFPage()
            ctx.closePDF()
        }
        let pdfData = mutableData as Data

        let dateStr = DateFormatter.yyyyMMdd.string(from: Date())
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Parcours_\(dateStr).pdf")
        try? pdfData.write(to: url)
        pdfURL = url
    }
}

// MARK: - Document view (used in sheet + render)

struct ParcoursDocumentView: View {
    let vm: ParcoursViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            documentHeader

            Divider()

            if vm.entries.isEmpty {
                Text("Aucun frein sélectionné dans ce parcours.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(vm.entries.enumerated()), id: \.element.id) { i, entry in
                    if i > 0 { Divider() }
                    ParcoursEntrySection(entry: entry)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var documentHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Parcours d'insertion")
                .font(.title.bold())
            Label(Date().formatted(date: .long, time: .omitted), systemImage: "calendar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !vm.adresse.isEmpty {
                Label(vm.adresse, systemImage: "mappin.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let commune = vm.communeGeocodee {
                Label("Localisé à \(commune)", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.tint)
            }
        }
    }
}

// MARK: - Entry section

private struct ParcoursEntrySection: View {
    let entry: ParcoursEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(entry.frein.titre)
                .font(.headline)

            Text(entry.frein.description)
                .font(.body)
                .foregroundStyle(.secondary)

            if !entry.services.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Services recommandés")
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)

                    ForEach(entry.services.prefix(5), id: \.service.id) { item in
                        ServiceExportRow(service: item.service, distance: item.distance)
                    }
                    if entry.services.count > 5 {
                        Text("+ \(entry.services.count - 5) autres services")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            } else {
                Text("Aucun service associé.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Service row

private struct ServiceExportRow: View {
    let service: DIService
    let distance: Double?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "smallcircle.filled.circle")
                .font(.system(size: 8))
                .padding(.top, 4)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(service.nom)
                    .font(.body)
                if !service.addressLine.isEmpty {
                    Text(service.addressLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    if let tel = service.telephone {
                        Label(tel, systemImage: "phone")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    if let mail = service.courriel {
                        Label(mail, systemImage: "envelope")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            if let d = distance {
                Text(d < 1000 ? "\(Int(d)) m" : String(format: "%.1f km", d / 1000))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Helpers

private extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
