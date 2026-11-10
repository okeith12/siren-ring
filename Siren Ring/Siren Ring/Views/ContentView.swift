import SwiftUI

/// Main view displaying SIREN Ring connection status and emergency contacts management
struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @StateObject private var emergencyManager = EmergencyManager.shared
    @State private var showingContactsSheet = false
    @State private var showingShareSheet = false
    @State private var selectedContact: EmergencyContact?
    @State private var showingRegistrationForm = false

    /// body stacks the ring's status, its main button and the contacts, with the sheets they open.
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                RingStatusView(bluetoothManager: bluetoothManager)
                RingControls(bluetoothManager: bluetoothManager,
                             showingRegistrationForm: $showingRegistrationForm)
                Spacer()
                ContactListSection(emergencyManager: emergencyManager,
                                   showingContactsSheet: $showingContactsSheet,
                                   selectedContact: $selectedContact)
                Spacer()
#if DEBUG
                if RingParts.pretend { SimRingPanel(ring: SimRing.shared) }
#endif
            }
            .navigationTitle("SIREN Emergency")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbar }
            .sheet(isPresented: $showingContactsSheet) { AddContactView() }
            .sheet(isPresented: $showingShareSheet) { ShareContactView() }
            .sheet(item: $selectedContact) { contact in ContactDetailView(contact: contact) }
            .sheet(isPresented: $showingRegistrationForm) {
                DeviceRegistrationView(bluetoothManager: bluetoothManager)
            }
            .sheet(isPresented: Binding(get: { bluetoothManager.newRing != nil },
                                        set: { if !$0 { bluetoothManager.newRing = nil } })) {
                RingConnectedCard(sirenId: bluetoothManager.newRing ?? "")
            }
        }
    }

    /// toolbar is deregister on the left, shown only while a registered ring is connected so it
    /// never looks tappable when it cannot act, and share on the right.
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if bluetoothManager.ringReady && !bluetoothManager.showRegistrationButton {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { bluetoothManager.deregisterDevice() }) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.red)
                }
                .accessibilityLabel("Deregister")
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showingShareSheet = true }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.blue)
            }
        }
    }
}
