import SwiftUI
import MapKit

enum MapLayer: String, CaseIterable {
    case structures = "Structures"
    case services   = "Services"
}

struct CombinedMapView: View {
    let structures: [DIStructure]
    let services: [DIService]

    @State private var layer: MapLayer = .structures
    @State private var selectedStructure: DIStructure?
    @State private var selectedService: DIService?
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 43.3, longitude: 5.4),
            span: MKCoordinateSpan(latitudeDelta: 0.8, longitudeDelta: 0.8)
        )
    )

    private var locatableStructures: [DIStructure] { structures.filter { $0.coordinate != nil } }
    private var locatableServices:   [DIService]   { services.filter   { $0.coordinate != nil } }

    private var count: Int {
        layer == .structures ? locatableStructures.count : locatableServices.count
    }

    var body: some View {
        Map(position: $position) {
            if layer == .structures {
                ForEach(locatableStructures) { structure in
                    Annotation(structure.nom, coordinate: structure.coordinate!) {
                        Image(systemName: "building.2.fill")
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(.tint, in: Circle())
                            .scaleEffect(selectedStructure?.id == structure.id ? 1.3 : 1.0)
                            .animation(.spring(duration: 0.2), value: selectedStructure?.id)
                            .onTapGesture {
                                selectedService = nil
                                selectedStructure = (selectedStructure?.id == structure.id) ? nil : structure
                            }
                    }
                }
            } else {
                ForEach(locatableServices) { service in
                    Annotation(service.nom, coordinate: service.coordinate!) {
                        Image(systemName: "hands.and.sparkles.fill")
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(.orange, in: Circle())
                            .scaleEffect(selectedService?.id == service.id ? 1.3 : 1.0)
                            .animation(.spring(duration: 0.2), value: selectedService?.id)
                            .onTapGesture {
                                selectedStructure = nil
                                selectedService = (selectedService?.id == service.id) ? nil : service
                            }
                    }
                }
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
            MapUserLocationButton()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                if let structure = selectedStructure {
                    StructureCallout(structure: structure, onDismiss: { selectedStructure = nil })
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if let service = selectedService {
                    ServiceCallout(service: service, onDismiss: { selectedService = nil })
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedStructure?.id)
        .animation(.easeInOut(duration: 0.25), value: selectedService?.id)
        .onChange(of: layer) {
            selectedStructure = nil
            selectedService = nil
        }
        .navigationTitle("Carte (\(count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Couche", selection: $layer) {
                    ForEach(MapLayer.allCases, id: \.self) { l in
                        Text(l.rawValue).tag(l)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
        }
    }
}

// MARK: - Structure callout

private struct StructureCallout: View {
    let structure: DIStructure
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(structure.nom)
                    .font(.headline)
                    .lineLimit(2)
                if !structure.addressLine.isEmpty {
                    Text(structure.addressLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let tel = structure.telephone {
                    Text(tel)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            VStack(spacing: 8) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                NavigationLink(destination: StructureDetailView(structure: structure)) {
                    Image(systemName: "chevron.right.circle.fill")
                        .foregroundStyle(.tint)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - Service callout

private struct ServiceCallout: View {
    let service: DIService
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(service.nom)
                    .font(.headline)
                    .lineLimit(2)
                if let type_ = service.type {
                    Text(type_)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !service.addressLine.isEmpty {
                    Text(service.addressLine)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            VStack(spacing: 8) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                NavigationLink(destination: ServiceDetailView(service: service)) {
                    Image(systemName: "chevron.right.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
