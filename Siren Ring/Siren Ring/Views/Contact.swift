import SwiftUI

struct AddContactView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var phoneNumber = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Contact Information")) {
                    TextField("Name", text: $name)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let contact = EmergencyContact(name: name, phoneNumber: phoneNumber)
                    EmergencyManager.shared.addEmergencyContact(contact)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty || phoneNumber.isEmpty)
            )
        }
    }
}