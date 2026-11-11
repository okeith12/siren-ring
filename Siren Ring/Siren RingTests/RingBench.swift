// The app's ring handling on fakes: the real BluetoothManager and RingGate, with the radio,
// the family alert and the server stood in for, so the tests run on the phone with no ring.
import Foundation
import Testing
@testable import Siren_Ring

let ours = "5a83ccfcefc611"
let theirs = "0b1c2d3e4f5a6b"

/// FakeRadio records what the app asked of the radio.
final class FakeRadio: RingRadio {
    weak var events: RingRadioEvents?
    var scans = 0
    var reconnects = 0
    var listens = 0
    var refusals = 0
    var told: [Bool] = []

    /// scan counts a search for rings.
    func scan() { scans += 1 }
    /// reconnect counts a standing reconnect.
    func reconnect() { reconnects += 1 }
    /// drop is never asked of the radio by the app; RingLink uses it inside refuse.
    func drop(byUser: Bool) {}
    /// refuse counts a ring turned away.
    func refuse() { refusals += 1 }
    /// listen counts subscriptions to alerts.
    func listen() { listens += 1 }
    /// tellRegistered keeps each answer written to the ring.
    func tellRegistered(_ registered: Bool) { told.append(registered) }
    /// sound is never asked of the radio by BluetoothManager; only the debug button calls it.
    func sound() {}
}

/// FakeAlerts records what would have reached the family and the user.
final class FakeAlerts: RingAlerting {
    var ons = 0
    var offs = 0
    var pairedIds: [String] = []

    /// on counts alarms that would have gone to the family.
    func on() { ons += 1 }
    /// off counts alarms stopped.
    func off() { offs += 1 }
    /// paired keeps each ring announced to the user.
    func paired(_ sirenId: String) { pairedIds.append(sirenId) }
}

/// FakeRegistration answers as the test says the server would.
struct FakeRegistration: RingRegistering {
    let accepts: Bool

    /// register answers at once, as the server would.
    func register(sirenId: String, user: String, name: String, done: @escaping (Bool) -> Void) {
        done(accepts)
    }
}

/// Bench is one BluetoothManager on fakes, with storage of its own.
final class Bench {
    let radio = FakeRadio()
    let alerts = FakeAlerts()
    let store: UserDefaults
    let manager: BluetoothManager

    /// init gives the phone a saved pairing, or none, and a server that accepts or refuses.
    init(paired: String? = nil, accepts: Bool = true, store: UserDefaults? = nil) throws {
        let fresh = UserDefaults(suiteName: "bench-\(UUID().uuidString)")
        self.store = try #require(store ?? fresh)
        if let paired { self.store.set(paired, forKey: RingStore.pairingKey) }
        manager = BluetoothManager(radio: radio, alerts: alerts,
                                   registration: FakeRegistration(accepts: accepts), store: self.store)
    }

    /// connect links a ring and lets it say who it is.
    func connect(_ text: String) {
        manager.linked()
        manager.heardInfo(Data(text.utf8))
    }

    /// pairing is what the phone has saved as its ring.
    var pairing: String? { store.string(forKey: RingStore.pairingKey) }
}
