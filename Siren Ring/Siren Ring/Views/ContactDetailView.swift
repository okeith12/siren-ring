import SwiftUI

struct ContactDetailView: View {
    let contact: EmergencyContact
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 15) {
                    Image(systemName: contact.contactType.iconName)
                        .font(.system(size: 60))
                        .foregroundColor(colorForContactType(contact.contactType))

                    Text(contact.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(contact.contactType.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()

                VStack(alignment: .leading, spacing: 15) {
                    if let phone = contact.phoneNumber {
                        DetailRow(title: "Phone Number", value: phone, icon: "phone")
                    }

                    if let deviceID = contact.deviceID {
                        DetailRow(title: "Device ID", value: deviceID, icon: "app.badge")
                    }

                    DetailRow(title: "Has App", value: contact.hasApp ? "Yes" : "No", icon: "checkmark.circle")
                    DetailRow(title: "Connection Status", value: contact.isConnected ? "Connected" : "Not Connected", icon: contact.isConnected ? "wifi" : "wifi.slash")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Contact Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Delete", role: .destructive) {
                        EmergencyManager.shared.removeEmergencyContact(contact)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func colorForContactType(_ contactType: ContactType) -> Color {
        switch contactType {
        case .appConnected:
            return .green
        case .appInstalled:
            return .blue
        case .phoneOnly:
            return .orange
        case .unknown:
            return .gray
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(title)
                .fontWeight(.medium)

            Spacer()

            Text(value)
                .foregroundColor(.secondary)
        }
    }
}