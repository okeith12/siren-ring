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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 15) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Add Emergency Contact")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Add someone to receive your emergency alerts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 20) {
                    // Contact Name (only show for phone method)
                    if selectedMethod == .phone {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contact Name")
                                .font(.headline)

                            TextField("Full Name", text: $contactName)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    // Contact Method Picker
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
                    
                    // Contact Information Input
                    if selectedMethod == .phone {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.headline)
                            
                            TextField("+1 (555) 123-4567", text: $phoneNumber)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.phonePad)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Authentication Code")
                                .font(.headline)
                            
                            TextField("000000", text: $authCode)
                                .font(.system(size: 24, weight: .medium, design: .monospaced))
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .textCase(.uppercase)
                                .multilineTextAlignment(.center)
                                .onChange(of: authCode) { _, newValue in
                                    if newValue.count > 6 {
                                        authCode = String(newValue.prefix(6))
                                    }
                                }
                        }
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
                
                // Instructions
                VStack(spacing: 10) {
                    Text("Contact Methods:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Phone: Receives SMS emergency alerts", systemImage: "phone.fill")
                            .foregroundColor(.orange)
                        Label("App Code: Full SIREN app integration", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        if selectedMethod == .app {
                            Divider()
                            Label("Ask them to open SIREN app", systemImage: "1.circle")
                            Label("They tap 'Share Contact Info'", systemImage: "2.circle")
                            Label("Enter their 6-digit code above", systemImage: "3.circle")
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                
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
    
    private func isFormValid() -> Bool {
        if selectedMethod == .phone {
            return !contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return authCode.count == 6
        }
    }
    
    private func addContact() {
        isLoading = true
        
        if selectedMethod == .phone {
            addPhoneContact()
        } else {
            addAppContact()
        }
    }
    
    private func addPhoneContact() {
        let contact = EmergencyContact(name: contactName.trimmingCharacters(in: .whitespacesAndNewlines), 
                                     phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines))
        
        // Add to local storage
        EmergencyManager.shared.addEmergencyContact(contact)
        
        // TODO: Also send to Go server for backup
        // ContactManager.addContactToServer(contact) { success in ... }
        
        isLoading = false
        presentationMode.wrappedValue.dismiss()
    }
    
    private func addAppContact() {
        ContactManager.lookupContactByCode(authCode) { contactInfo in
            guard let info = contactInfo else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Code not found or expired. Please ask your contact to generate a new code."
                    self.showingError = true
                }
                return
            }

            let contact = EmergencyContact(
                name: info.name,
                deviceID: info.deviceID,
                phoneNumber: self.phoneNumber.isEmpty ? nil : self.phoneNumber
            )

            DispatchQueue.main.async {
                EmergencyManager.shared.addEmergencyContact(contact)
                self.isLoading = false
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

#Preview {
    AddContactView()
}