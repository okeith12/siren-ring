import SwiftUI

/// View for adding new emergency contacts using authentication codes
struct AddContactView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var authCode = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
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
                    
                    Text("Enter the 6-digit code from your emergency contact")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Authentication Code")
                            .font(.headline)
                        
                        TextField("000000", text: $authCode)
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .textCase(.uppercase)
                            .multilineTextAlignment(.center)
                            .onChange(of: authCode) { newValue in
                                // Limit to 6 digits
                                if newValue.count > 6 {
                                    authCode = String(newValue.prefix(6))
                                }
                            }
                    }
                    
                    Button("Add Contact") {
                        addContactWithCode()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(authCode.count != 6 || isLoading)
                    
                    if isLoading {
                        ProgressView("Looking up contact...")
                            .font(.subheadline)
                    }
                }
                
                VStack(spacing: 10) {
                    Text("How to get a code:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Contact opens SIREN Ring app", systemImage: "1.circle")
                        Label("They tap 'Share Contact Info'", systemImage: "2.circle")
                        Label("They give you the 6-digit code", systemImage: "3.circle")
                        Label("Code expires in 10 minutes", systemImage: "clock")
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
    
    /// Looks up contact by authentication code and adds them
    private func addContactWithCode() {
        isLoading = true
        
        EmergencyContactAuth.lookupContactByCode(authCode) { name, deviceToken in
            isLoading = false
            
            guard let contactName = name, let appID = deviceToken else {
                errorMessage = "Code not found or expired. Please ask your contact to generate a new code."
                showingError = true
                return
            }
            
            // Create and add the contact
            let contact = EmergencyContact(name: contactName, appID: appID)
            EmergencyManager.shared.addEmergencyContact(contact)
            
            // Close the view
            presentationMode.wrappedValue.dismiss()
        }
    }
}
}