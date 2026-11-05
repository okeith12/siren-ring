import Faults
import Foundation

/// Verdict is what the app does with a ring that has just said who it is.
public enum Verdict: Equatable, Sendable {
    /// mine is the paired ring: listen for its alerts.
    case mine(registered: Bool)
    /// newlyPaired is a registered ring met with no pairing: paired at once, like AirPods.
    case newlyPaired(String)
    /// unregistered is a ring nobody has registered: offer Register, do not listen.
    case unregistered(String)
    /// stranger is a ring that is not the paired one: drop it and look for ours.
    case stranger
    /// refused is not a ring's answer at all: recorded and ignored.
    case refused
}

/// AfterDrop is what the app does once a ring's link is gone.
public enum AfterDrop: Equatable, Sendable {
    case reconnect, scan, stay
}

/// RingGate is the one place the app judges what a ring sends, so no alert reaches the family
/// until the ring has proven it is the paired one.
public struct RingGate: Sendable {
    public private(set) var pairedId: String?
    public private(set) var faults: FaultLog
    private var current: Verdict?

    /// init forgets a saved pairing that is not a Siren id, because only old firmware made one.
    public init(savedPairing: String?, faults: FaultLog = FaultLog()) {
        self.faults = faults
        pairedId = savedPairing
        if let saved = savedPairing, !RingInfo.isSirenId(saved) {
            self.faults.record(.badPairing, Array(saved.utf8))
            pairedId = nil
        }
    }

    /// looksAtLaunch is true when there is a ring to find without the user asking.
    public var looksAtLaunch: Bool { pairedId != nil }

    /// listening is true only while the connected ring has proven it is the paired one.
    public var listening: Bool {
        switch current {
        case .mine?, .newlyPaired?: return true
        default: return false
        }
    }

    /// connected starts a new link with nothing proven yet.
    public mutating func connected() {
        current = nil
    }

    /// heard judges the ring's device info and pairs a registered ring when there is none.
    public mutating func heard(info data: Data?) -> Verdict {
        current = judge(data)
        return current ?? .refused
    }

    /// pair keeps the ring the user just registered; a non-Siren id is refused.
    public mutating func pair(_ sirenId: String) -> Bool {
        guard RingInfo.isSirenId(sirenId) else {
            faults.record(.badPairing, Array(sirenId.utf8))
            return false
        }
        pairedId = sirenId
        if current == .unregistered(sirenId) { current = .mine(registered: true) }
        return true
    }

    /// forget drops the pairing, so no ring is listened to until one pairs again.
    public mutating func forget() {
        pairedId = nil
        current = nil
    }

    /// alert returns on (true) or off (false) only from the proven ring; anything else is nil.
    public mutating func alert(_ data: Data?) -> Bool? {
        let head = Self.head(data)
        guard current != nil else {
            faults.record(.alertBeforeCheck, head)
            return nil
        }
        guard listening else {
            faults.record(.alertNotListened, head)
            return nil
        }
        guard head.count == 1, let byte = head.first, byte <= 1 else {
            faults.record(.badAlertByte, head)
            return nil
        }
        return byte == 1
    }

    /// dropped says what to do once the link is gone; the user leaving always wins.
    public mutating func dropped(userLeft: Bool) -> AfterDrop {
        let wasOurs = listening
        current = nil
        if userLeft || pairedId == nil { return .stay }
        return wasOurs ? .reconnect : .scan
    }

    /// record keeps a failure the app hit outside the gate, so every fault lives in one log.
    public mutating func record(_ kind: FaultKind, _ bytes: [UInt8] = []) {
        faults.record(kind, bytes)
    }

    /// judge decides who the ring is; a registered ring met with no pairing becomes ours.
    private mutating func judge(_ data: Data?) -> Verdict {
        guard let info = RingInfo.parse(data) else {
            faults.record(.badRingInfo, Self.head(data))
            return .refused
        }
        if let pairedId {
            return info.sirenId == pairedId ? .mine(registered: info.registered) : .stranger
        }
        guard info.registered else { return .unregistered(info.sirenId) }
        pairedId = info.sirenId
        return .newlyPaired(info.sirenId)
    }

    /// head keeps one byte more than a fault holds, enough to tell a one-byte alert from a longer
    /// write, so a huge write costs no more than a small one.
    private static func head(_ data: Data?) -> [UInt8] {
        Array((data ?? Data()).prefix(Fault.maxBytes + 1))
    }
}
