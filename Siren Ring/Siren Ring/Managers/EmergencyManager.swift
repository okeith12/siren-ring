import Foundation
import UserNotifications
import UIKit
import CoreLocation
import RingCore

/// Manages emergency contacts and alert distribution via Go server and APNs
class EmergencyManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = EmergencyManager()

    @Published var emergencyContacts: [EmergencyContact] = []

    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    /// init loads the saved contacts and asks for location, which goes into every alarm.
    private override init() {
        super.init()
        setupLocationManager()
        loadEmergencyContacts()
    }

    /// setupLocationManager asks for location while the app is in use.
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Triggers emergency alert to all contacts via Go server and APNs
    func sendEmergencyAlert() {
        locationManager.requestLocation()

        let userName = BluetoothManager.shared.userName.isEmpty ? "Someone" : BluetoothManager.shared.userName
        let locationText = formatLocation()
        let message = "\(userName) has triggered an emergency alert.\nCurrent location: \(locationText)"

        report(message)
    }

    /// formatLocation is an Apple Maps link to the last known location, which opens as a pin.
    private func formatLocation() -> String {
        guard let location = currentLocation else {
            return "Location unavailable"
        }

        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        return "https://maps.apple.com/?ll=\(latitude),\(longitude)&q=Emergency%20Location"
    }
    
    /// report sends the alarm to the server, which pushes it to every contact's phone; a failure
    /// is shown here, so the user knows nobody was told.
    private func report(_ message: String) {
        let alerted = emergencyContacts.map {
            Alerted(name: $0.name, phone: $0.phoneNumber ?? "", deviceId: $0.deviceID ?? "")
        }
        let emergency = Emergency(userId: BluetoothManager.shared.deviceUUID, message: message,
                                  timestamp: ISO8601DateFormatter().string(from: Date()), contacts: alerted)
        guard let body = ServerWire.body(emergency) else { return showLocalErrorNotification() }
        SirenServer().send("/api/emergency", body) { [weak self] status, _ in
            if status != 200 { self?.showLocalErrorNotification() }
        }
    }

    /// Shows error notification if server request fails
    private func showLocalErrorNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Emergency Alert Failed"
        content.body = "Unable to notify emergency contacts. Check connection."
        content.sound = .defaultCritical
        
        let request = UNNotificationRequest(
            identifier: "emergency-error-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Loads emergency contacts from persistent storage
    private func loadEmergencyContacts() {
        if let data = UserDefaults.standard.data(forKey: "emergencyContacts"),
           let contacts = try? JSONDecoder().decode([EmergencyContact].self, from: data) {
            emergencyContacts = contacts
        } else {
            emergencyContacts = []
        }
    }
    
    /// Adds new emergency contact to the list
    /// - Parameter contact: Emergency contact to add
    func addEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        saveEmergencyContacts()
    }
    
    /// Removes emergency contact at specified index
    /// - Parameter index: Index of contact to remove
    func removeEmergencyContact(at index: Int) {
        emergencyContacts.remove(at: index)
        saveEmergencyContacts()
    }

    /// Removes emergency contact by ID
    /// - Parameter contact: Emergency contact to remove
    func removeEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.removeAll { $0.id == contact.id }
        saveEmergencyContacts()
    }
    
    /// Persists emergency contacts to UserDefaults
    private func saveEmergencyContacts() {
        if let data = try? JSONEncoder().encode(emergencyContacts) {
            UserDefaults.standard.set(data, forKey: "emergencyContacts")
        }
    }

    /// locationManager keeps the newest location for the next alarm.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    /// locationManager drops a location it can no longer vouch for, so the alarm says unavailable.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        currentLocation = nil
    }
}
