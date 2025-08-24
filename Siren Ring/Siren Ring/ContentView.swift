import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @StateObject private var emergencyManager = EmergencyManager.shared
    @State private var showingContactsSheet = false
    
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
                HStack(spacing: 20) {
                    Button(action: { bluetoothManager.startScanning() }) {
                        Label("Scan", systemImage: "magnifyingglass")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(bluetoothManager.isConnected)
                    
                    Button(action: { bluetoothManager.disconnect() }) {
                        Label("Disconnect", systemImage: "xmark")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!bluetoothManager.isConnected)
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
                    }
                    
                    if emergencyManager.emergencyContacts.isEmpty {
                        Text("No emergency contacts added")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(emergencyManager.emergencyContacts) { contact in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(contact.name)
                                        .fontWeight(.medium)
                                    Text(contact.phoneNumber)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("SIREN Emergency")
            .sheet(isPresented: $showingContactsSheet) {
                AddContactView()
            }
        }
        .onAppear {
            requestNotificationPermission()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
