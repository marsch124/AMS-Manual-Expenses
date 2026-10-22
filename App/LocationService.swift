import CoreLocation

/// Finds the country the phone is in and that country's currency.
@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var currency: String?
    @Published private(set) var placeName: String?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func refresh() {
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        default: break
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in self.refresh() }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in await self.lookUp(location) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    private func lookUp(_ location: CLLocation) async {
        guard let mark = try? await geocoder.reverseGeocodeLocation(location).first,
              let countryCode = mark.isoCountryCode else { return }
        placeName = [mark.locality, mark.country].compactMap { $0 }.joined(separator: ", ")
        currency = Locale(identifier: "en_\(countryCode)").currency?.identifier
    }
}
