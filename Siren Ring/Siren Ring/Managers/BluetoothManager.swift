import Faults
import Foundation
import RingCore

/// BluetoothManager is the app's view of its ring: everything the radio hears goes to RingGate,
/// and the app acts only on the gate's verdict.
final class BluetoothManager: NSObject, ObservableObject, RingRadioEvents {
    static let shared = BluetoothManager(radio: RingLink(), alerts: RingAlerts(),
                                         registration: RingRegistration(), store: .standard)

    @Published var isConnected = false
    @Published var connectionStatus = "Disconnected"
    @Published var emergencyActive = false
    @Published var lastAlert = "No alerts"
    @Published var deviceUUID = ""
    @Published var showRegistrationButton = false
    @Published var mySirenRing = ""
    @Published var newRing: String?
    @Published var userName = ""
    @Published var customDeviceName = ""

    private let radio: RingRadio
    private let alerts: RingAlerting
    private let registration: RingRegistering
    private let store: RingStore
    private var gate: RingGate

    /// init loads the pairing and the fault log, so both survive the app being killed; an old
    /// pairing the gate forgets is cleared from storage at once.
    init(radio: RingRadio, alerts: RingAlerting, registration: RingRegistering, store: UserDefaults) {
        self.radio = radio
        self.alerts = alerts
        self.registration = registration
        self.store = RingStore(defaults: store)
        gate = RingGate(savedPairing: self.store.pairing, faults: self.store.faults())
        super.init()
        radio.events = self
        mySirenRing = gate.pairedId ?? ""
        save()
    }

    /// faultCount is how many refusals are on record, counting those the full log dropped.
    var faultCount: Int { gate.faults.faults.count + Int(gate.faults.dropped) }

    /// startScanning is the Scan button: look for any SIREN ring.
    func startScanning() {
        connectionStatus = "Scanning for SIREN Rings..."
        radio.scan()
    }

    /// registerDevice registers the connected ring with the server; only a vetted id is sent.
    func registerDevice() {
        let sirenId = deviceUUID
        guard RingInfo.isSirenId(sirenId) else { return }
        connectionStatus = "Registering device..."
        registration.register(sirenId: sirenId, user: userName, name: customDeviceName) { [weak self] ok in
            self?.radio.tellRegistered(ok)
            self?.keep(sirenId, registered: ok)
        }
    }

    /// deregisterDevice tells the ring it is no longer registered.
    func deregisterDevice() {
        guard !deviceUUID.isEmpty else { return }
        radio.tellRegistered(false)
        showRegistrationButton = true
        connectionStatus = "Device connected - Not registered"
    }

    /// ready goes looking for the paired ring as soon as Bluetooth is on, with no tap.
    func ready() {
        if gate.looksAtLaunch { startScanning() }
    }

    /// linked starts a new link with nothing proven.
    func linked() {
        gate.connected()
        isConnected = true
        connectionStatus = "Connected - checking ring"
    }

    /// lost does what the gate says once a link is gone: reconnect ours, look again, or stay.
    func lost(userLeft: Bool) {
        isConnected = false
        connectionStatus = "Disconnected"
        switch gate.dropped(userLeft: userLeft) {
        case .reconnect: radio.reconnect()
        case .scan: radio.scan()
        case .stay: break
        }
    }

    /// heardInfo acts on the gate's verdict on who the ring is.
    func heardInfo(_ data: Data?) {
        let verdict = gate.heard(info: data)
        save()
        switch verdict {
        case .mine(let registered):
            show(ours: gate.pairedId ?? "", registered: registered)
            radio.listen()
        case .newlyPaired(let sirenId):
            announce(sirenId)
            alerts.paired(sirenId)
            radio.listen()
        case .unregistered(let sirenId): offerRegistration(sirenId)
        case .stranger:
            connectionStatus = "Wrong SIREN Ring"
            radio.refuse()
        case .refused: notReady()
        }
    }

    /// heardAlert passes on only what the gate lets through; anything else is already recorded.
    func heardAlert(_ data: Data?) {
        guard let on = gate.alert(data) else { return save() }
        emergencyActive = on
        let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        lastAlert = (on ? "EMERGENCY ACTIVE - " : "Emergency stopped - ") + time
        if on { alerts.on() } else { alerts.off() }
    }

    /// alertFailed records an alarm notification iOS would not show.
    func alertFailed() {
        gate.record(.notificationFailed)
        save()
    }

    /// keep pairs a ring the server took and listens to it; a refusal leaves the phone unpaired.
    private func keep(_ sirenId: String, registered ok: Bool) {
        guard ok, gate.pair(sirenId) else {
            save()
            connectionStatus = "Registration failed"
            return
        }
        save()
        mySirenRing = sirenId
        show(ours: sirenId, registered: true)
        radio.listen()
    }

    /// save keeps the pairing and the fault log on the phone; a log it could not write is
    /// recorded, so the next save carries the failure too.
    private func save() {
        if !store.save(pairing: gate.pairedId, faults: gate.faults) { gate.record(.logNotSaved) }
    }
}
