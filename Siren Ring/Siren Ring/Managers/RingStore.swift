import Faults
import Foundation

/// RingStore keeps the pairing and the fault log on the phone, so both survive the app being
/// killed; what it hands back is unvetted until RingGate has judged it.
struct RingStore {
    static let pairingKey = "paired_siren_ring"
    static let faultsKey = "ring_faults"
    let defaults: UserDefaults

    /// pairing is the saved ring id, exactly as stored.
    var pairing: String? { defaults.string(forKey: Self.pairingKey) }

    /// faults loads the saved log; one that will not load is replaced and the loss recorded.
    func faults() -> FaultLog {
        var fresh = FaultLog()
        guard let data = defaults.data(forKey: Self.faultsKey) else { return fresh }
        do {
            return try JSONDecoder().decode(FaultLog.self, from: data)
        } catch {
            fresh.record(.badSavedLog, Array(data.prefix(Fault.maxBytes)))
            return fresh
        }
    }

    /// save keeps both, and reports false when the log could not be written.
    func save(pairing: String?, faults: FaultLog) -> Bool {
        defaults.set(pairing, forKey: Self.pairingKey)
        guard let data = try? JSONEncoder().encode(faults) else { return false }
        defaults.set(data, forKey: Self.faultsKey)
        return true
    }
}
