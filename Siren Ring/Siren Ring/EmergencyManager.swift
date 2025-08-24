import Foundation
import MessageUI

class EmergencyManager: ObservableObject {
    static let shared = EmergencyManager()
    
    @Published var emergencyContacts: [EmergencyContact] = []
    
    private init() {
        loadEmergencyContacts()
    }
    
    // Call this when emergency is triggered (without location for now)
    func sendEmergencyAlert() {
        let message = createEmergencyMessage()
        
        for contact in emergencyContacts {
            sendSMS(to: contact.phoneNumber, message: message)
        }
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
    
    private func createEmergencyMessage() -> String {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        
        var message = "EMERGENCY ALERT\n"
        message += "SIREN Ring activated at \(timestamp)\n"
        message += "Please check on me immediately."
        
        // TODO: Add location when implemented
        /*
        if let location = location {
            let lat = String(format: "%.6f", location.coordinate.latitude)
            let lon = String(format: "%.6f", location.coordinate.longitude)
            message += "Location: \(lat), \(lon)\n"
            message += "Maps: https://maps.apple.com/?q=\(lat),\(lon)"
        } else {
            message += "Location: Unable to determine"
        }
        */
        
        return message
    }
    
    private func sendSMS(to phoneNumber: String, message: String) {
        if MFMessageComposeViewController.canSendText() {
            // This requires presenting from a view controller
            // For now, we'll just log the message
            print("Sending SMS to \(phoneNumber): \(message)")
        }
    }
    
    private func loadEmergencyContacts() {
        if let data = UserDefaults.standard.data(forKey: "emergencyContacts"),
           let contacts = try? JSONDecoder().decode([EmergencyContact].self, from: data) {
            emergencyContacts = contacts
        } else {
            // Default empty array
            emergencyContacts = []
        }
    }
    
    func addEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        saveEmergencyContacts()
    }
    
    func removeEmergencyContact(at index: Int) {
        emergencyContacts.remove(at: index)
        saveEmergencyContacts()
    }
    
    private func saveEmergencyContacts() {
        if let data = try? JSONEncoder().encode(emergencyContacts) {
            UserDefaults.standard.set(data, forKey: "emergencyContacts")
        }
    }
}