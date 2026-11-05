// Which ring this is: the paired one, a new one to pair, or a stranger.
import Faults
import Foundation
import Testing
@testable import RingCore

let ours = "5a83ccfcefc611"
let theirs = "0b1c2d3e4f5a6b"

/// info is a ring's device info as the radio hands it over.
func info(_ id: String, _ registered: Bool) -> Data { Data("\(id),\(registered)".utf8) }

/// gate is a fresh connection on a phone paired with paired, or with nothing.
func gate(_ paired: String?) -> RingGate {
    var g = RingGate(savedPairing: paired)
    g.connected()
    return g
}

/// Case 9: the ring this phone is paired with is ours.
@Test func the_paired_ring_is_mine() {
    var g = gate(ours)
    let r1 = g.heard(info: info(ours, true))
    #expect(r1 == .mine(registered: true))
}

/// Auto-pair: a phone with no pairing pairs with a registered ring at once, like AirPods.
@Test func with_no_pairing_a_registered_ring_pairs_itself() {
    var g = gate(nil)
    let r2 = g.heard(info: info(ours, true))
    #expect(r2 == .newlyPaired(ours))
    #expect(g.pairedId == ours)
}

/// Case 10: a ring nobody registered is offered for Register, never paired on its own.
@Test func with_no_pairing_an_unregistered_ring_waits_for_register() {
    var g = gate(nil)
    let r3 = g.heard(info: info(ours, false))
    #expect(r3 == .unregistered(ours))
    #expect(g.pairedId == nil)
}

/// Case 11: a phone already paired never pairs over its own ring.
@Test func a_different_ring_is_a_stranger_even_when_registered() {
    var g = gate(ours)
    let r4 = g.heard(info: info(theirs, true))
    #expect(r4 == .stranger)
    #expect(g.pairedId == ours)
}

/// Case 12: a pairing from the old firmware is forgotten and recorded, so the new ring can pair.
@Test func a_pairing_that_is_not_a_siren_id_is_forgotten_at_launch() {
    let g = RingGate(savedPairing: "abc123def4567")
    #expect(g.pairedId == nil)
    #expect(g.faults.faults.first?.kind == .badPairing)
}

/// Case 14: registering a ring pairs it, and the app listens to it from then on.
@Test func a_ring_registered_by_the_user_is_paired_and_listened_to() {
    var g = gate(nil)
    _ = g.heard(info: info(ours, false))
    let r5 = g.pair(ours)
    #expect(r5)
    #expect(g.pairedId == ours)
    #expect(g.listening)
}

/// Attack: pairing with something that is not a Siren id is refused and recorded.
@Test func pairing_with_a_non_siren_id_is_refused_and_recorded() {
    var g = gate(nil)
    let r6 = g.pair("notready")
    #expect(r6 == false)
    #expect(g.pairedId == nil)
    #expect(g.faults.faults.first?.kind == .badPairing)
}

/// Device info that is not a ring's answer is recorded and changes nothing.
@Test func garbage_device_info_is_refused_and_recorded() {
    var g = gate(ours)
    let r7 = g.heard(info: Data("notready,false".utf8))
    #expect(r7 == .refused)
    #expect(g.faults.faults.first?.kind == .badRingInfo)
    #expect(g.listening == false)
}

/// Forgetting the ring means its alerts are no longer heard.
@Test func a_forgotten_ring_is_no_longer_listened_to() {
    var g = gate(ours)
    _ = g.heard(info: info(ours, true))
    g.forget()
    #expect(g.pairedId == nil)
    #expect(g.listening == false)
}

/// A failure the app reports, such as a log it could not save, is kept with the ring's faults.
@Test func a_failure_the_app_reports_is_kept_in_the_log() {
    var g = gate(ours)
    g.record(.logNotSaved)
    #expect(g.faults.faults.first?.kind == .logNotSaved)
}
