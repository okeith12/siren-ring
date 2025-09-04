import Foundation

/// Emergency contact model for push notification delivery via Go server
struct EmergencyContact: Identifiable, Codable {
    let id = UUID()
    let name: String
    let appID: String
    
    /// Initializes an emergency contact for push notifications
    /// - Parameters:
    ///   - name: Full name of the emergency contact
    ///   - appID: Device token for APNs push notifications
    init(name: String, appID: String) {
        self.name = name
        self.appID = appID
    }
}

