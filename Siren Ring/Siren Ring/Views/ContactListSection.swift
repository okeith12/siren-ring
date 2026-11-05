import SwiftUI

/// ContactListSection lists the emergency contacts, with Add, tap for details, and delete.
struct ContactListSection: View {
    @ObservedObject var emergencyManager: EmergencyManager
    @Binding var showingContactsSheet: Bool
    @Binding var selectedContact: EmergencyContact?

    /// body is the header with Add, then the contacts or a note that there are none.
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Emergency Contacts")
                    .font(.headline)
                Spacer()
                Button("Add") { showingContactsSheet = true }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            if emergencyManager.emergencyContacts.isEmpty {
                Text("No emergency contacts added")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(emergencyManager.emergencyContacts) { contact in
                    Button(action: { selectedContact = contact }) {
                        ContactRow(contact: contact)
                    }
                }
                .onDelete(perform: deleteContact)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    /// deleteContact removes the swiped contacts.
    private func deleteContact(at offsets: IndexSet) {
        for index in offsets {
            emergencyManager.removeEmergencyContact(at: index)
        }
    }
}
