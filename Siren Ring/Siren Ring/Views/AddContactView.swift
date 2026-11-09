import SwiftUI

/// View for adding new emergency contacts via phone number or authentication code
struct AddContactView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var contactName = ""
    @State private var phoneNumber = ""
    @State private var authCode = ""
    @State private var selectedMethod: ContactMethod = .phone
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    enum ContactMethod: String, CaseIterable {
        case phone = "Phone Number"
        case app = "SIREN App Code"
    }
    
    /// body is the header, the form for the picked method, and help on both methods.
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                AddContactHeader()
                
                VStack(spacing: 20) {
                    if selectedMethod == .phone {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contact Name")
                                .font(.headline)

                            TextField("Full Name", text: $contactName)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contact Method")
                            .font(.headline)
                        
                        Picker("Contact Method", selection: $selectedMethod) {
                            ForEach(ContactMethod.allCases, id: \.self) { method in
                                Text(method.rawValue).tag(method)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    if selectedMethod == .phone {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.headline)
                            
                            TextField("+1 (555) 123-4567", text: $phoneNumber)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.phonePad)
                        }
                    } else {
                        CodeField(code: $authCode)
                    }
                    
                    Button("Add Contact") {
                        addContact()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!isFormValid() || isLoading)
                    
                    if isLoading {
                        ProgressView("Adding contact...")
                            .font(.subheadline)
                    }
                }
                
                ContactMethodsHelp(byCode: selectedMethod == .app)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    /// isFormValid needs a name and number for a phone contact, or a six-digit code.
    private func isFormValid() -> Bool {
        if selectedMethod == .phone {
            return !contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return authCode.count == 6
        }
    }
    
    /// addContact adds the contact by the picked method.
    private func addContact() {
        isLoading = true
        
        if selectedMethod == .phone {
            addPhoneContact()
        } else {
            addAppContact()
        }
    }
    
    /// addPhoneContact keeps a contact reached by phone on this phone.
    private func addPhoneContact() {
        let contact = EmergencyContact(name: contactName.trimmingCharacters(in: .whitespacesAndNewlines), 
                                     phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines))
        
        EmergencyManager.shared.addEmergencyContact(contact)
        
        isLoading = false
        presentationMode.wrappedValue.dismiss()
    }
    
    /// addAppContact finds the contact the code belongs to; only a vetted answer is kept.
    private func addAppContact() {
        ContactManager.lookup(authCode) { card in
            isLoading = false
            guard let card else {
                errorMessage = "Code not found or expired. Please ask your contact to generate a new code."
                return showingError = true
            }
            EmergencyManager.shared.addEmergencyContact(EmergencyContact(
                name: card.name, deviceID: card.sirenId,
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber))
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    AddContactView()
}