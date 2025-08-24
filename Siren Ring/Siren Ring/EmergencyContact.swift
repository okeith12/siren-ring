import Foundation

struct EmergencyContact: Identifiable, Codable {
    let id = UUID()
    let name: String
    let phoneNumber: String
}

