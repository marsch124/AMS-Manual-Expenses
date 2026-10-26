import CoreLocation
import ExpenseCore

/// Finds the country the phone is in and that country's currency, and (1.7) the GPS fix
/// saved with each new expense.
@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var currency: String?
    @Published private(set) var placeName: String?
    /// The latest GPS fix. UI tests set it with `-uiTestingFix <latitude>,<longitude>`.
    @Published private(set) var fix: Fix?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        // 1.7: the best the phone can do, so a shop can be told from the one next door.
        manager.desiredAccuracy = kCLLocationAccuracyBest
        let arguments = ProcessInfo.processInfo.arguments
        if ExpensesApp.uiTesting, let i = arguments.firstIndex(of: "-uiTestingFix"), i + 1 < arguments.count {
            // <latitude>,<longitude>[,<accuracy in metres>]
            let parts = arguments[i + 1].split(separator: ",").compactMap { Double($0) }
            if parts.count >= 2 {
                fix = Fix(latitude: parts[0], longitude: parts[1], accuracy: parts.count > 2 ? parts[2] : nil)
                placeName = "Stockholm, Sweden"
            }
        }
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
        Task { @MainActor in
            self.fix = Fix(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude,
                           accuracy: location.horizontalAccuracy >= 0 ? location.horizontalAccuracy : nil)
            await self.lookUp(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    private func lookUp(_ location: CLLocation) async {
        guard let mark = try? await geocoder.reverseGeocodeLocation(location).first,
              let countryCode = mark.isoCountryCode else { return }
        placeName = [mark.locality, mark.country].compactMap { $0 }.joined(separator: ", ")
        currency = Locale(identifier: "en_\(countryCode)").currency?.identifier
    }
}
