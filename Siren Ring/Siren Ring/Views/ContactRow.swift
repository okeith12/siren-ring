import SwiftUI

/// ContactRow shows one emergency contact: how they are reached and whether they are connected.
struct ContactRow: View {
    let contact: EmergencyContact

    /// body is the type icon, the contact's details, the connection badge and a chevron.
    var body: some View {
        HStack {
            Image(systemName: contact.contactType.iconName)
                .font(.title2)
                .foregroundColor(contact.contactType.color)
                .frame(width: 30)
            details
            Spacer()
            if contact.hasApp {
                Image(systemName: contact.isConnected ? "wifi" : "wifi.slash")
                    .font(.caption)
                    .foregroundColor(contact.isConnected ? .green : .orange)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    /// details is the name, the contact type, and the phone or device the alert goes to.
    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(contact.name)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Text(contact.contactType.description)
                .font(.caption)
                .foregroundColor(.secondary)
            if let phone = contact.phoneNumber {
                Label(phone, systemImage: "phone")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            if let deviceID = contact.deviceID {
                Label("Device: \(String(deviceID.prefix(8)))...", systemImage: "app.badge")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

extension ContactType {
    /// color is the one color each contact type is drawn in, wherever it shows.
    var color: Color {
        switch self {
        case .appConnected: return .green
        case .appInstalled: return .blue
        case .phoneOnly: return .orange
        case .unknown: return .gray
        }
    }
}
