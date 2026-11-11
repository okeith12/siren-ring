// The pretend ring says only what the real ring would, so a SIREN_ENV=sim run shows what a
// phone would show.
#if DEBUG
import Foundation
import Testing
@testable import Siren_Ring

/// Heard keeps every event the pretend ring raised, in order.
final class Heard: RingRadioEvents {
    var said: [String] = []

    /// ready keeps Bluetooth coming on.
    func ready() { said.append("ready") }
    /// linked keeps a ring connecting.
    func linked() { said.append("linked") }
    /// lost keeps a link going and who ended it.
    func lost(userLeft: Bool) { said.append("lost \(userLeft)") }
    /// heardInfo keeps the device info as text.
    func heardInfo(_ data: Data?) { said.append("info " + String(decoding: data ?? Data(), as: UTF8.self)) }
    /// heardAlert keeps the alert bytes.
    func heardAlert(_ data: Data?) { said.append("alert \(Array(data ?? Data()))") }
}

/// sim is a pretend ring whose events land at once, with someone listening.
func sim() -> (SimRing, Heard) {
    let ring = SimRing(post: { $0() })
    let heard = Heard()
    ring.events = heard
    heard.said.removeAll()
    return (ring, heard)
}

/// A ring in range links and says who it is when the app scans.
@Test func a_ring_in_range_links_and_says_who_it_is_on_scan() {
    let (ring, heard) = sim()
    ring.place("\(ours),true")
    ring.scan()
    #expect(heard.said == ["linked", "info \(ours),true"])
}

/// With no ring in range a scan finds nothing.
@Test func with_no_ring_in_range_a_scan_finds_nothing() {
    let (ring, heard) = sim()
    ring.scan()
    #expect(heard.said.isEmpty)
}

/// A press reaches the app only once the app listens, as the real ring sends only then.
@Test func a_press_reaches_the_app_only_once_it_listens() {
    let (ring, heard) = sim()
    ring.place("\(ours),true")
    ring.scan()
    ring.press(true)
    ring.listen()
    ring.press(true)
    ring.press(false)
    #expect(heard.said.suffix(2) == ["alert [1]", "alert [0]"])
    #expect(heard.said.count == 4)
}

/// Walking away drops the link, and coming back answers the standing reconnect.
@Test func a_ring_walking_away_drops_and_comes_back_to_a_reconnect() {
    let (ring, heard) = sim()
    ring.place("\(ours),true")
    ring.scan()
    ring.away(true)
    ring.reconnect()
    ring.away(false)
    #expect(heard.said == ["linked", "info \(ours),true", "lost false", "linked", "info \(ours),true"])
}

/// A refused ring is never linked again, so the app cannot loop on a stranger.
@Test func a_refused_ring_is_never_linked_again() {
    let (ring, heard) = sim()
    ring.place("\(theirs),true")
    ring.scan()
    ring.refuse()
    ring.scan()
    #expect(heard.said == ["linked", "info \(theirs),true", "lost false"])
}

/// Telling the ring it is registered changes what it says on the next link.
@Test func a_registered_ring_says_so_on_the_next_link() {
    let (ring, heard) = sim()
    ring.place("\(ours),false")
    ring.scan()
    ring.tellRegistered(true)
    ring.drop(byUser: true)
    ring.scan()
    #expect(heard.said.last == "info \(ours),true")
}

/// The app sounding the ring comes back as the ring's own alarm, as the debug ring sends it.
@Test func sounding_the_ring_comes_back_as_its_alarm() {
    let (ring, heard) = sim()
    ring.place("\(ours),true")
    ring.scan()
    ring.listen()
    ring.sound()
    #expect(heard.said.last == "alert [1]")
}

/// A ring the app is not listening to cannot be heard sounding, so nothing comes back.
@Test func sounding_a_ring_not_listened_to_sends_nothing_back() {
    let (ring, heard) = sim()
    ring.place("\(ours),true")
    ring.scan()
    ring.sound()
    #expect(!heard.said.contains("alert [1]"))
}
#endif
