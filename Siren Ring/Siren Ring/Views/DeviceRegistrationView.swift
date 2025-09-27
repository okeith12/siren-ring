import SwiftUI

struct DeviceRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var bluetoothManager: BluetoothManager

    // No local state needed - using BluetoothManager properties directly

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)

                    Text("Register SIREN Ring")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Device UUID: \(bluetoothManager.deviceUUID)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top, 20)

                // Registration Form
                VStack(alignment: .leading, spacing: 16) {
                    // Device Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Device Name")
                            .font(.headline)
                        TextField("Enter device name (e.g., John's Ring)", text: $bluetoothManager.customDeviceName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // Phone Number Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Name")
                            .font(.headline)
                        TextField("Enter your name (e.g., Larry Sam)", text: $bluetoothManager.userName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.default)
                    }

                    Text("This information will be used to identify your SIREN Ring and register it with the emergency system.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                Spacer()

                // Register Button
                VStack(spacing: 12) {
                    Button(action: registerDevice) {
                        Text("Register Device")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(!isFormValid)

                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Device Registration")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var isFormValid: Bool {
        !bluetoothManager.customDeviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !bluetoothManager.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func registerDevice() {
        guard isFormValid else { return }

        // Call the bluetooth manager's registration (uses the dynamic properties we set)
        bluetoothManager.registerDevice()

        // Close the form - the main view will show updated status via @Published properties
        dismiss()
    }
}

#Preview {
    DeviceRegistrationView(bluetoothManager: BluetoothManager.shared)
}