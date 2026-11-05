// The app finds its ring on its own, goes back for it after a drop, and never fights the user.
import Foundation
import Testing
@testable import Siren_Ring

/// A pairing from the old firmware is cleared at launch, so the new ring can pair.
@Test func an_old_pairing_is_cleared_at_launch() throws {
    let b = try Bench(paired: "abc123def4567")
    #expect(b.manager.mySirenRing == "")
    #expect(b.pairing == nil)
}

/// With a pairing saved, Bluetooth coming on sends the app looking for its ring with no tap.
@Test func with_a_pairing_the_app_looks_for_its_ring_without_a_tap() throws {
    let b = try Bench(paired: ours)
    b.manager.ready()
    #expect(b.radio.scans == 1)
}

/// With no pairing there is no ring to look for until the user taps Scan.
@Test func with_no_pairing_the_app_waits_for_scan() throws {
    let b = try Bench()
    b.manager.ready()
    #expect(b.radio.scans == 0)
}

/// The paired ring dropping, say out of range, is reconnected at once.
@Test func the_paired_ring_dropping_is_reconnected_at_once() throws {
    let b = try Bench(paired: ours)
    b.connect("\(ours),true")
    b.manager.lost(userLeft: false)
    #expect(b.radio.reconnects == 1)
    #expect(b.manager.isConnected == false)
}

/// A link the user ended stays down.
@Test func a_ring_the_user_left_stays_down() throws {
    let b = try Bench(paired: ours)
    b.connect("\(ours),true")
    b.manager.lost(userLeft: true)
    #expect(b.radio.reconnects == 0)
    #expect(b.radio.scans == 0)
}

/// After turning a stranger away the app looks for its own ring, never the stranger.
@Test func after_a_stranger_the_app_looks_for_its_own_ring() throws {
    let b = try Bench(paired: ours)
    b.connect("\(theirs),true")
    b.manager.lost(userLeft: false)
    #expect(b.radio.scans == 1)
    #expect(b.radio.reconnects == 0)
}
