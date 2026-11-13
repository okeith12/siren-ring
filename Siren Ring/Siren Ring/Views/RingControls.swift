import SwiftUI

/// RingControls is the one main button: Register a new ring, Scan for one, or raise a manual
/// emergency once the ring is ours.
struct RingControls: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Binding var showingRegistrationForm: Bool
    /// appRaised is set by Start Ring, the only alarm the app may stop.
    @State private var appRaised = false

    /// ready is true once our registered ring has proven itself, which turns Scan into Manual
    /// Emergency.
    private var ready: Bool {
        bluetoothManager.ringReady && !bluetoothManager.showRegistrationButton
    }

    /// stopping is true while the alarm the app started is sounding.
    private var stopping: Bool { bluetoothManager.emergencyActive && appRaised }

    /// body picks the button for where the ring stands.
    var body: some View {
        VStack {
            if bluetoothManager.showRegistrationButton {
                Button(action: { showingRegistrationForm = true }) {
                    wide(Label("Register", systemImage: "plus.circle"), .orange)
                }
            } else if ready {
                Button(action: { EmergencyManager.shared.sendEmergencyAlert() }) {
                    wide(Label("Manual Emergency", systemImage: "exclamationmark.triangle.fill"), .red)
                }
#if DEBUG
                Button(action: {
                    if !bluetoothManager.emergencyActive { appRaised = true }
                    RingParts.radio.sound()
                }) {
                    wide(Label(stopping ? "Stop Ring" : "Start Ring",
                               systemImage: "hand.tap.fill"), .purple)
                }
                .onChange(of: bluetoothManager.emergencyActive) { _, on in
                    if !on { appRaised = false }
                }
#endif
            } else {
                Button(action: { bluetoothManager.startScanning() }) {
                    wide(Label("Scan", systemImage: "magnifyingglass"), .blue)
                }
            }
        }
        .padding(.horizontal)
    }

    /// wide gives every main button the same full-width look.
    private func wide(_ label: Label<Text, Image>, _ color: Color) -> some View {
        label
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}
