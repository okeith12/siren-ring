// After a drop the app goes back for its own ring, and never fights the user.
import Testing
@testable import RingCore

/// Case 19: the paired ring dropping, say out of range, is reconnected at once.
@Test func the_paired_ring_dropping_is_reconnected() {
    var g = gate(ours)
    _ = g.heard(info: info(ours, true))
    let r1 = g.dropped(userLeft: false)
    #expect(r1 == .reconnect)
}

/// Case 20: with a pairing saved the app looks for its ring at launch, with no tap.
@Test func with_a_pairing_the_app_looks_for_its_ring_at_launch() {
    #expect(RingGate(savedPairing: ours).looksAtLaunch)
    #expect(RingGate(savedPairing: nil).looksAtLaunch == false)
}

/// Case 21: a link the user ended stays down.
@Test func a_ring_the_user_disconnected_stays_disconnected() {
    var g = gate(ours)
    _ = g.heard(info: info(ours, true))
    let r2 = g.dropped(userLeft: true)
    #expect(r2 == .stay)
}

/// Case 22: a stranger is never reconnected; the app goes looking for its own ring.
@Test func a_dropped_stranger_sends_the_app_looking_for_its_own_ring() {
    var g = gate(ours)
    _ = g.heard(info: info(theirs, true))
    let r3 = g.dropped(userLeft: false)
    #expect(r3 == .scan)
}

/// A ring newly paired is ours, so it is reconnected like the paired ring.
@Test func a_newly_paired_ring_dropping_is_reconnected() {
    var g = gate(nil)
    _ = g.heard(info: info(ours, true))
    let r4 = g.dropped(userLeft: false)
    #expect(r4 == .reconnect)
}

/// With no pairing there is nothing to go back for, so the app waits for the user.
@Test func with_no_pairing_a_drop_waits_for_the_user() {
    var g = gate(nil)
    _ = g.heard(info: info(ours, false))
    let r5 = g.dropped(userLeft: false)
    #expect(r5 == .stay)
}
