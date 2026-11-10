import Foundation

/// FaultKind names what the app refused or what failed, so the analyzer can tell them apart.
public enum FaultKind: UInt8, Codable, Sendable {
    case badRingInfo, alertBeforeCheck, alertNotListened, badAlertByte, badPairing, assertFailed
    case badSavedLog, logNotSaved, notificationFailed
}

/// Fault is one record: its kind, when it happened, and the first bytes of what was refused.
public struct Fault: Equatable, Codable, Sendable {
    public static let maxBytes = 8
    public let kind: FaultKind
    public let at: Date
    public let bytes: [UInt8]
}

/// FaultLog keeps the first 16 faults and only counts the rest, so it never grows and never
/// stops the app; it is Codable so the app can keep it across a kill.
public struct FaultLog: Codable, Sendable {
    public static let capacity = 16
    public private(set) var faults: [Fault] = []
    public private(set) var dropped: UInt32 = 0

    /// init reserves every slot up front, so recording never allocates.
    public init() {
        faults.reserveCapacity(Self.capacity)
    }

    /// init(from:) loads a saved log the same way it is recorded: never more than 16 kept, the
    /// rest counted, and every slot reserved, so storage can never make it grow.
    public init(from decoder: Decoder) throws {
        let saved = try decoder.container(keyedBy: CodingKeys.self)
        let loaded = try saved.decode([Fault].self, forKey: .faults)
        let over = loaded.count - Self.capacity
        faults.reserveCapacity(Self.capacity)
        faults.append(contentsOf: loaded.prefix(Self.capacity))
        let total = UInt64(try saved.decode(UInt32.self, forKey: .dropped)) + UInt64(max(over, 0))
        dropped = UInt32(min(total, UInt64(UInt32.max)))
    }

    /// record keeps a fault while there is room and counts it once the log is full.
    public mutating func record(_ kind: FaultKind, _ bytes: [UInt8] = [], at: Date = Date()) {
        guard faults.count < Self.capacity else {
            if dropped < UInt32.max { dropped += 1 }
            return
        }
        faults.append(Fault(kind: kind, at: at, bytes: Array(bytes.prefix(Fault.maxBytes))))
    }

    /// check is the app's assertion: a false holds is recorded with its site and never halts.
    public mutating func check(_ holds: Bool, site: UInt8, at: Date = Date()) -> Bool {
        if !holds { record(.assertFailed, [site], at: at) }
        return holds
    }
}
