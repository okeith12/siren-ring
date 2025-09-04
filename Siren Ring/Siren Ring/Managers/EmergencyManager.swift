import Foundation
import UserNotifications

/// Manages emergency contacts and alert distribution via Go server and APNs
class EmergencyManager: ObservableObject {
    static let shared = EmergencyManager()
    
    @Published var emergencyContacts: [EmergencyContact] = []
    
    private init() {
        loadEmergencyContacts()
    }
    
    /// Triggers emergency alert to all contacts via Go server and APNs
    func sendEmergencyAlert() {
        // Show local notification that alert is being sent
        sendLocalEmergencyNotification()
        
        // Send to Go server for APNs delivery
        sendEmergencyToServer()
    }
    
    // TODO: Location functionality - commented out for now
    /*
    func sendEmergencyAlert(location: Location?) {
        let message = createEmergencyMessage(location: location)
        
        for contact in emergencyContacts {
            sendSMS(to: contact.phoneNumber, message: message)
        }
    }
    */
    
    /// Sends HTTP request to Go server with emergency data
    private func sendEmergencyToServer() {
        // TODO: Replace with your actual Go server URL
        let serverURL = "https://your-go-server.com/api/emergency"
        
        guard let url = URL(string: serverURL) else {
            print("Invalid server URL")
            return
        }
        
        let emergencyData = createEmergencyPayload()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: emergencyData)
        } catch {
            print("Failed to encode emergency data: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Emergency server request failed: \(error)")
                    self.showLocalErrorNotification()
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Emergency alert sent successfully to \(self.emergencyContacts.count) contacts")
                    } else {
                        print("Server returned error: \(httpResponse.statusCode)")
                        self.showLocalErrorNotification()
                    }
                }
            }
        }.resume()
    }
    
    /// Creates JSON payload for Go server
    /// - Returns: Dictionary containing emergency data
    private func createEmergencyPayload() -> [String: Any] {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let deviceTokens = emergencyContacts.map { $0.appID }
        
        return [
            "emergency_type": "siren_ring_activation",
            "timestamp": timestamp,
//            "user_id": UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            "device_tokens": deviceTokens,
            "message": "EMERGENCY ALERT - SIREN Ring activated. Please check on me immediately.",
            "priority": "critical"
            // TODO: Add location when implemented
        ]
    }
    
    /// Shows local notification on this device about emergency status
    private func sendLocalEmergencyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "SIREN Ring Emergency Active"
        content.body = "Emergency alert sent to \(emergencyContacts.count) contacts"
        content.sound = .defaultCritical
        
        let request = UNNotificationRequest(
            identifier: "local-emergency-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
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
            // Default empty array
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
    
    /// Persists emergency contacts to UserDefaults
    private func saveEmergencyContacts() {
        if let data = try? JSONEncoder().encode(emergencyContacts) {
            UserDefaults.standard.set(data, forKey: "emergencyContacts")
        }
    }
}
