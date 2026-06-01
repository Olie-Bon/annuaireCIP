import SwiftUI
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

// MARK: - Export sheet

struct StructureExportSheet: View {
    let structure: DIStructure
    let services: [DIService]
    @Environment(\.dismiss) private var dismiss
    @State private var pdfURL: URL?
    @State private var isRendering = false

    var body: some View {
        NavigationStack {
            ScrollView {
                StructureDocumentView(structure: structure, services: services)
                    .padding(24)
            }
            .background(Color(white: 0.96))
            .navigationTitle(structure.nom)
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
                                preview: SharePreview("\(structure.nom).pdf", image: Image(systemName: "doc.richtext"))
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

        let content = StructureDocumentView(structure: structure, services: services)
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
        let safeName = structure.nom
            .components(separatedBy: .init(charactersIn: "/\\:*?\"<>|"))
            .joined(separator: "_")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Structure_\(safeName)_\(dateStr).pdf")
        try? pdfData.write(to: url)
        pdfURL = url
    }
}

// MARK: - Document view

struct StructureDocumentView: View {
    let structure: DIStructure
    let services: [DIService]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            documentHeader

            Divider()

            // Contacts
            if structure.telephone != nil || structure.courriel != nil || structure.siteWeb != nil {
                exportSection("Contacts") {
                    if let tel = structure.telephone {
                        exportRow(icon: "phone", value: tel)
                    }
                    if let email = structure.courriel {
                        exportRow(icon: "envelope", value: email)
                    }
                    if let web = structure.siteWeb {
                        exportRow(icon: "globe", value: web)
                    }
                }
            }

            if let horaires = structure.horairesAccueil {
                exportSection("Horaires d'accueil") {
                    Text(horaires).font(.body)
                }
            }

            if let desc = structure.description {
                exportSection("Description") {
                    Text(desc).font(.body)
                }
            }

            if let acces = structure.accessibiliteLieu {
                exportSection("Accessibilité") {
                    Text(acces).font(.body)
                }
            }

            if let reseaux = structure.reseauxPorteurs, !reseaux.isEmpty {
                exportSection("Réseaux porteurs") {
                    Text(reseaux.joined(separator: " · "))
                        .font(.body)
                }
            }

            Divider()

            // Services
            exportSection("Services associés (\(services.count))") {
                if services.isEmpty {
                    Text("Aucun service associé.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(services.enumerated()), id: \.element.id) { i, service in
                        if i > 0 {
                            Divider().padding(.vertical, 4)
                        }
                        StructureServiceExportRow(service: service)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var documentHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(structure.nom)
                .font(.title.bold())
            Label(Date().formatted(date: .long, time: .omitted), systemImage: "calendar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !structure.addressLine.isEmpty {
                Label(structure.addressLine, systemImage: "mappin.circle")
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

    private func exportRow(icon: String, value: String) -> some View {
        Label(value, systemImage: icon)
            .font(.body)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Service row

private struct StructureServiceExportRow: View {
    let service: DIService

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "hands.and.sparkles.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 12))
                Text(service.nom)
                    .font(.subheadline.bold())
            }

            if let type_ = service.type {
                Text(type_)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !service.description.isEmpty {
                Text(service.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(4)
            }

            HStack(spacing: 16) {
                if let frais = service.frais {
                    Label(frais, systemImage: "eurosign.circle")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                if let publics = service.publics, !publics.isEmpty {
                    Label(publics.joined(separator: ", "), systemImage: "person.2")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if !service.addressLine.isEmpty {
                Label(service.addressLine, systemImage: "mappin")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 16) {
                if let tel = service.telephone {
                    Label(tel, systemImage: "phone")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                if let mail = service.courriel {
                    Label(mail, systemImage: "envelope")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
