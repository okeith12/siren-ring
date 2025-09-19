import SwiftUI
import UserNotifications

/// Main view displaying SIREN Ring connection status and emergency contacts management
struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @StateObject private var emergencyManager = EmergencyManager.shared
    @State private var showingContactsSheet = false
    @State private var showingShareSheet = false
    @State private var selectedContact: EmergencyContact?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // SIREN Ring Status
                VStack {
                    Image(systemName: bluetoothManager.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(bluetoothManager.isConnected ? .green : .red)
                    
                    Text("SIREN Ring")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(bluetoothManager.connectionStatus)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Emergency Status
                VStack {
                    if bluetoothManager.emergencyActive {
                        Label("EMERGENCY ACTIVE", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    Text(bluetoothManager.lastAlert)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Connection Controls
                VStack {
                    if bluetoothManager.showRegistrationButton {
                        Button(action: { bluetoothManager.registerDevice() }) {
                            Label("Register", systemImage: "plus.circle")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: { bluetoothManager.startScanning() }) {
                            Label("Scan", systemImage: "magnifyingglass")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(bluetoothManager.isConnected && !bluetoothManager.showRegistrationButton)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Emergency Contacts Section
                VStack(alignment: .leading) {
                    HStack {
                        Text("Emergency Contacts")
                            .font(.headline)
                        Spacer()
                        Button("Add") {
                            showingContactsSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    
                    if emergencyManager.emergencyContacts.isEmpty {
                        Text("No emergency contacts added")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(emergencyManager.emergencyContacts) { contact in
                            Button(action: {
                                selectedContact = contact
                            }) {
                                HStack {
                                    // Contact Type Icon
                                    VStack {
                                        Image(systemName: contact.contactType.iconName)
                                            .font(.title2)
                                            .foregroundColor(colorForContactType(contact.contactType))
                                    }
                                    .frame(width: 30)

                                    // Contact Information
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(contact.name)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        Text(contact.contactType.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        // Show contact method details
                                        if let phone = contact.phoneNumber {
                                            HStack {
                                                Image(systemName: "phone")
                                                    .font(.caption2)
                                                Text(phone)
                                                    .font(.caption2)
                                            }
                                            .foregroundColor(.secondary)
                                        }

                                        if let appID = contact.appID {
                                            HStack {
                                                Image(systemName: "app.badge")
                                                    .font(.caption2)
                                                Text("Device: \(String(appID.prefix(8)))...")
                                                    .font(.caption2)
                                            }
                                            .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    // Connection Status
                                    VStack {
                                        if contact.hasApp {
                                            Image(systemName: contact.isConnected ? "wifi" : "wifi.slash")
                                                .font(.caption)
                                                .foregroundColor(contact.isConnected ? .green : .orange)
                                        }
                                    }

                                    // Chevron indicator
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .onDelete(perform: deleteContact)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("SIREN Emergency")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingContactsSheet) {
                AddContactView()
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareContactView()
            }
            .sheet(item: $selectedContact) { contact in
                ContactDetailView(contact: contact)
            }
        }
        .onAppear {
            requestNotificationPermission()
        }
    }
    
    /// Requests notification permission from the user
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    /// Deletes emergency contact at specified index
    /// - Parameter offsets: IndexSet containing indices to delete
    private func deleteContact(at offsets: IndexSet) {
        for index in offsets {
            emergencyManager.removeEmergencyContact(at: index)
        }
    }
    
    /// Returns SwiftUI Color for contact type
    /// - Parameter contactType: The contact type
    /// - Returns: Appropriate Color for the contact type
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
