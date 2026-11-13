#if DEBUG
import Foundation

/// SimRing stands in for the ring with SIREN_ENV=sim, so the app runs with no ring or Bluetooth.
/// It says only what the real ring would: device info on connect, and alerts once subscribed.
final class SimRing: RingRadio {
    static let shared = SimRing()
    static let refuseMax = 8

    weak var events: RingRadioEvents? { didSet { post { [weak self] in self?.events?.ready() } } }
    private let post: (@escaping () -> Void) -> Void
    private var info: String?
    private var gone = false
    private var looking = false
    private var linked = false
    private var listening = false
    private var alarmOn = false
    private var appRaised = false
    private var refused: [String] = []

    /// init takes how events are delivered: later on the main queue, as CoreBluetooth does, so a
    /// refusal that rescans never calls back into itself.
    init(post: @escaping (@escaping () -> Void) -> Void = { DispatchQueue.main.async(execute: $0) }) {
        self.post = post
        refused.reserveCapacity(Self.refuseMax)
    }

    /// scan looks until a ring is in range.
    func scan() {
        looking = true
        meet()
    }

    /// reconnect is a standing connect, which for a pretend ring is the same as looking.
    func reconnect() { scan() }

    /// drop ends the link and says who ended it.
    func drop(byUser: Bool) {
        guard linked else { return }
        linked = false
        listening = false
        post { [weak self] in self?.events?.lost(userLeft: byUser) }
    }

    /// refuse drops the ring and never links it again, oldest refusal first out.
    func refuse() {
        guard linked, let id else { return }
        if refused.count >= Self.refuseMax { refused.removeFirst() }
        refused.append(id)
        drop(byUser: false)
    }

    /// listen subscribes, which is when the real ring starts sending alerts.
    func listen() { listening = linked }

    /// tellRegistered changes what the ring says about itself next time, as the ring keeps it.
    func tellRegistered(_ registered: Bool) {
        guard linked, let id else { return }
        info = "\(id),\(registered)"
    }

    /// place puts a different ring in range; the one linked now goes first.
    func place(_ next: String) {
        drop(byUser: false)
        info = next
        meet()
    }

    /// press sends the alarm on or off, only to an app that subscribed.
    func press(_ on: Bool) {
        alarmOn = on
        appRaised = false
        guard listening else { return }
        post { [weak self] in self?.events?.heardAlert(Data([on ? 1 : 0])) }
    }

    /// sound toggles only an alarm the app started, as the real ring does.
    func sound() {
        guard listening, !alarmOn || appRaised else { return }
        press(!alarmOn)
        appRaised = alarmOn
    }

    /// away takes the ring out of range, or brings it back to whatever the app is waiting with.
    func away(_ out: Bool) {
        gone = out
        if out { drop(byUser: false) } else { meet() }
    }

    /// id is the Siren ID part of what the ring says.
    private var id: String? { info?.split(separator: ",").first.map(String.init) }

    /// meet links the ring in range if the app is looking for one and it was not refused.
    private func meet() {
        guard looking, !linked, !gone, let info, let id, !refused.contains(id) else { return }
        looking = false
        linked = true
        post { [weak self] in
            self?.events?.linked()
            self?.events?.heardInfo(Data(info.utf8))
        }
    }
}

/// SimRegistration is a pretend server that takes every ring, so Register can be tapped
/// through before sirenserv is running.
struct SimRegistration: RingRegistering {
    /// register answers yes on the main queue, as RingRegistration does.
    func register(sirenId: String, user: String, name: String, done: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { done(true) }
    }
}
#endif
