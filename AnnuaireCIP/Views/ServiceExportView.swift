import SwiftUI
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

// MARK: - Export sheet

struct ServiceExportSheet: View {
    let service: DIService
    @Environment(\.dismiss) private var dismiss
    @State private var pdfURL: URL?
    @State private var isRendering = false

    var body: some View {
        NavigationStack {
            ScrollView {
                ServiceDocumentView(service: service)
                    .padding(24)
            }
            .background(Color(white: 0.96))
            .navigationTitle(service.nom)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    if isRendering {
                        ProgressView()
                    } else {
                        Button {
                            Task {
                                if pdfURL == nil { await renderPDF() }
                                if let url = pdfURL { openSavePanel(url) }
                            }
                        } label: {
                            Label("Télécharger PDF", systemImage: "arrow.down.circle.fill")
                        }
                        if let url = pdfURL {
                            ShareLink(
                                item: url,
                                preview: SharePreview("\(service.nom).pdf", image: Image(systemName: "doc.richtext"))
                            ) {
                                Label("Partager", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 620, idealWidth: 700, minHeight: 500, idealHeight: 680)
        #endif
    }

    private func openSavePanel(_ source: URL) {
        #if os(macOS)
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = source.lastPathComponent
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        panel.allowedContentTypes = [UTType.pdf]
        panel.prompt = "Enregistrer"
        guard panel.runModal() == .OK, let dest = panel.url else { return }
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: source, to: dest)
        #endif
    }

    @MainActor
    private func renderPDF() async {
        isRendering = true
        defer { isRendering = false }

        let content = ServiceDocumentView(service: service)
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
        let safeName = service.nom
            .components(separatedBy: .init(charactersIn: "/\\:*?\"<>|"))
            .joined(separator: "_")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Service_\(safeName)_\(dateStr).pdf")
        try? pdfData.write(to: url)
        pdfURL = url
    }
}

// MARK: - Document view

struct ServiceDocumentView: View {
    let service: DIService

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            documentHeader

            Divider()

            exportSection("Description") {
                Text(service.description).font(.body)
            }

            if service.type != nil || !(service.thematiques ?? []).isEmpty {
                exportSection("Catégorie") {
                    if let type_ = service.type {
                        exportLabeledRow("Type", value: type_)
                    }
                    if let thematiques = service.thematiques, !thematiques.isEmpty {
                        exportLabeledRow("Thématiques", value: thematiques.joined(separator: " · "))
                    }
                }
            }

            if service.publics != nil || service.publicsPrecisions != nil || service.conditionsAcces != nil {
                exportSection("Public visé") {
                    if let publics = service.publics, !publics.isEmpty {
                        exportLabeledRow("Publics", value: publics.joined(separator: " · "))
                    }
                    if let precisions = service.publicsPrecisions {
                        exportLabeledRow("Précisions", value: precisions)
                    }
                    if let conditions = service.conditionsAcces {
                        exportLabeledRow("Conditions d'accès", value: conditions)
                    }
                }
            }

            if service.frais != nil || service.fraisPrecisions != nil {
                exportSection("Frais") {
                    if let frais = service.frais {
                        exportLabeledRow("Tarif", value: frais)
                    }
                    if let precisions = service.fraisPrecisions {
                        exportLabeledRow("Précisions", value: precisions)
                    }
                }
            }

            exportSection("Accueil") {
                if let modes = service.modesAccueil, !modes.isEmpty {
                    exportLabeledRow("Modes d'accueil", value: modes.joined(separator: " · "))
                }
                if !service.addressLine.isEmpty {
                    exportRow(icon: "mappin", value: service.addressLine)
                }
                if let zones = service.zoneEligibilite, !zones.isEmpty {
                    exportLabeledRow("Zone d'éligibilité", value: zones.joined(separator: " · "))
                }
            }

            if service.telephone != nil || service.courriel != nil || service.contactNomPrenom != nil {
                exportSection("Contact") {
                    if let contact = service.contactNomPrenom {
                        exportRow(icon: "person", value: contact)
                    }
                    if let tel = service.telephone {
                        exportRow(icon: "phone", value: tel)
                    }
                    if let mail = service.courriel {
                        exportRow(icon: "envelope", value: mail)
                    }
                }
            }

            if service.modesMobilisation != nil || service.mobilisablePar != nil
                || service.mobilisationPrecisions != nil || service.lienMobilisation != nil {
                exportSection("Mobilisation") {
                    if let modes = service.modesMobilisation, !modes.isEmpty {
                        exportLabeledRow("Modes", value: modes.joined(separator: " · "))
                    }
                    if let par = service.mobilisablePar, !par.isEmpty {
                        exportLabeledRow("Mobilisable par", value: par.joined(separator: " · "))
                    }
                    if let precisions = service.mobilisationPrecisions {
                        Text(precisions).font(.body)
                    }
                    if let lien = service.lienMobilisation {
                        exportRow(icon: "link", value: lien)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var documentHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(service.nom)
                .font(.title.bold())
            Label(Date().formatted(date: .long, time: .omitted), systemImage: "calendar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !service.addressLine.isEmpty {
                Label(service.addressLine, systemImage: "mappin.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func exportSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private func exportLabeledRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(label + " :")
                .font(.body.bold())
            Text(value)
                .font(.body)
        }
    }

    private func exportRow(icon: String, value: String) -> some View {
        Label(value, systemImage: icon)
            .font(.body)
            .foregroundStyle(.secondary)
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
