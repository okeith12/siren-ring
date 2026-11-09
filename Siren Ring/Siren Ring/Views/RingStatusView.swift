import SwiftUI

/// RingStatusView shows whether the proven ring is there and whether its alarm is sounding.
struct RingStatusView: View {
    @ObservedObject var bluetoothManager: BluetoothManager

    /// body is the connection badge, then the emergency banner and the last alert.
    var body: some View {
        VStack {
            Image(systemName: bluetoothManager.ringReady ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(bluetoothManager.ringReady ? .green : .red)
            Text("SIREN Ring")
                .font(.title2)
                .fontWeight(.bold)
            Text(bluetoothManager.connectionStatus)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
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
    }
}
