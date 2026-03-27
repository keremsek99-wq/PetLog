import SwiftUI
import MapKit

struct NearbyVetsView: View {
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedVet: MKMapItem?
    @State private var isSearching = false
    @State private var locationError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $position, selection: $selectedVet) {
                    UserAnnotation()

                    ForEach(searchResults, id: \.self) { item in
                        Marker(
                            item.name ?? "Veteriner",
                            systemImage: "cross.case.fill",
                            coordinate: item.placemark.coordinate
                        )
                        .tint(.red)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .onAppear {
                    searchNearbyVets()
                }

                VStack {
                    Spacer()

                    // Bottom info card
                    if let selected = selectedVet {
                        vetDetailCard(selected)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if searchResults.isEmpty && !isSearching {
                        noResultsCard
                    }
                }
                .animation(.spring(duration: 0.3), value: selectedVet)

                // Loading
                if isSearching {
                    VStack {
                        ProgressView("Yakındaki veterinerler aranıyor...")
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(.rect(cornerRadius: 12))
                        Spacer()
                    }
                    .padding(.top, 60)
                }
            }
            .navigationTitle("Yakındaki Veterinerler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        searchNearbyVets()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert("Konum Hatası", isPresented: .constant(locationError != nil)) {
                Button("Tamam") { locationError = nil }
            } message: {
                Text(locationError ?? "")
            }
        }
    }

    // MARK: - Vet Detail Card

    private func vetDetailCard(_ item: MKMapItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name ?? "Bilinmeyen Veteriner")
                        .font(.headline)
                    if let address = item.placemark.title {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Button {
                    selectedVet = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack(spacing: 16) {
                // Call
                if let phone = item.phoneNumber {
                    Link(destination: URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")!) {
                        Label("Ara", systemImage: "phone.fill")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }

                // Directions
                Button {
                    openInMaps(item)
                } label: {
                    Label("Yol Tarifi", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }

                Spacer()

                // Distance
                if let userLocation = CLLocationManager().location {
                    let vetLocation = CLLocation(
                        latitude: item.placemark.coordinate.latitude,
                        longitude: item.placemark.coordinate.longitude
                    )
                    let distance = userLocation.distance(from: vetLocation) / 1000
                    Text(String(format: "%.1f km", distance))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThickMaterial)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(radius: 8)
        .padding()
    }

    private var noResultsCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.slash")
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Veteriner Bulunamadı")
                    .font(.subheadline.weight(.semibold))
                Text("Konum iznini kontrol edin veya daha geniş alanda arayın.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThickMaterial)
        .clipShape(.rect(cornerRadius: 12))
        .padding()
    }

    // MARK: - Search

    private func searchNearbyVets() {
        isSearching = true
        searchResults = []

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "veteriner"
        request.resultTypes = .pointOfInterest

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                if let error {
                    locationError = error.localizedDescription
                    return
                }
                searchResults = response?.mapItems ?? []
            }
        }
    }

    private func openInMaps(_ item: MKMapItem) {
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
