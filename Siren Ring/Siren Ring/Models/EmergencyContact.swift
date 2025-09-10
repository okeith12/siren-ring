import Foundation

/// Emergency contact model supporting both phone and app-based contacts
struct EmergencyContact: Identifiable, Codable {
    let id = UUID()
    let name: String
    let phoneNumber: String?     // For SMS fallback
    let appID: String?          // Device token for APNs push notifications  
    let hasApp: Bool            // Whether they have SIREN app installed
    let isConnected: Bool       // Whether they're connected via app
    
    /// Contact type for visual indicators
    var contactType: ContactType {
        if hasApp && isConnected {
            return .appConnected
        } else if hasApp {
            return .appInstalled
        } else if phoneNumber != nil {
            return .phoneOnly
        } else {
            return .unknown
        }
    }
    
    /// Initializes an emergency contact with phone number only
    /// - Parameters:
    ///   - name: Full name of the emergency contact
    ///   - phoneNumber: Phone number for SMS notifications
    init(name: String, phoneNumber: String) {
        self.name = name
        self.phoneNumber = phoneNumber
        self.appID = nil
        self.hasApp = false
        self.isConnected = false
    }
    
    /// Initializes an emergency contact with app connection
    /// - Parameters:
    ///   - name: Full name of the emergency contact
    ///   - appID: Device token for APNs push notifications
    ///   - phoneNumber: Optional phone number for SMS fallback
    init(name: String, appID: String, phoneNumber: String? = nil) {
        self.name = name
        self.phoneNumber = phoneNumber
        self.appID = appID
        self.hasApp = true
        self.isConnected = true
    }
}

/// Contact type enumeration for visual indicators
enum ContactType {
    case appConnected    // Has app and is connected
    case appInstalled    // Has app but not connected
    case phoneOnly       // Phone number only
    case unknown         // No contact method
    
    var iconName: String {
        switch self {
        case .appConnected:
            return "checkmark.circle.fill"
        case .appInstalled:
            return "app.badge"
        case .phoneOnly:
            return "phone.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    var iconColor: String {
        switch self {
        case .appConnected:
            return "green"
        case .appInstalled:
            return "blue"
        case .phoneOnly:
            return "orange"
        case .unknown:
            return "gray"
        }
    }
    
    var description: String {
        switch self {
        case .appConnected:
            return "Connected via SIREN app"
        case .appInstalled:
            return "Has SIREN app"
        case .phoneOnly:
            return "SMS only"
        case .unknown:
            return "No contact method"
        }
    }
}

