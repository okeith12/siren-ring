import Foundation

/// How each of RingGate's verdicts shows on screen; nothing here touches the radio or the gate,
/// so only BluetoothManager itself can subscribe to alerts.
extension BluetoothManager {
    /// show marks the proven ring as ours, offering Register again if it says it is not.
    func show(ours sirenId: String, registered: Bool) {
        deviceUUID = sirenId
        showRegistrationButton = !registered
        connectionStatus = "My SIREN Ring ready"
    }

    /// announce shows a ring that just paired itself, like AirPods, and opens the card.
    func announce(_ sirenId: String) {
        mySirenRing = sirenId
        newRing = sirenId
        show(ours: sirenId, registered: true)
    }

    /// offerRegistration shows Register for a ring nobody has registered.
    func offerRegistration(_ sirenId: String) {
        deviceUUID = sirenId
        showRegistrationButton = true
        connectionStatus = "Device connected - Not registered"
    }

    /// notReady shows a ring with no id yet, so nothing unvetted can be registered.
    func notReady() {
        deviceUUID = ""
        showRegistrationButton = false
        connectionStatus = "SIREN Ring not ready"
    }
}
