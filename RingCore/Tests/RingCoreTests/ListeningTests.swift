// No alert reaches the family until the ring has proven it is the paired one.
import Faults
import Foundation
import Testing
@testable import RingCore

/// Case 13: the paired ring's on and off are heard once it has said who it is.
@Test func the_proven_ring_is_listened_to_for_on_and_off() {
    var g = gate(ours)
    _ = g.heard(info: info(ours, true))
    #expect(g.listening)
    let r1 = g.alert(Data([1]))
    #expect(r1 == true)
    let r2 = g.alert(Data([0]))
    #expect(r2 == false)
}

/// Case 15, attack: a stranger named SIREN-Ring sends 1; it alerts no one and is recorded.
@Test func a_stranger_ring_can_never_raise_an_alert() {
    var g = gate(ours)
    _ = g.heard(info: info(theirs, true))
    #expect(g.listening == false)
    let r3 = g.alert(Data([1]))
    #expect(r3 == nil)
    #expect(g.faults.faults.last?.kind == .alertNotListened)
}

/// Case 16: a ring nobody registered is not listened to.
@Test func an_unregistered_ring_is_not_listened_to() {
    var g = gate(nil)
    _ = g.heard(info: info(ours, false))
    #expect(g.listening == false)
    let r4 = g.alert(Data([1]))
    #expect(r4 == nil)
}

/// Case 17, attack: an alert sent before the ring said who it is is ignored and recorded.
@Test func an_alert_before_the_ring_is_checked_is_ignored() {
    var g = gate(ours)
    let r5 = g.alert(Data([1]))
    #expect(r5 == nil)
    #expect(g.faults.faults.first?.kind == .alertBeforeCheck)
}

/// Case 18: only 0 and 1 exist; anything else from the proven ring is refused and recorded.
@Test(arguments: [Data([2]), Data([0xFF]), Data([1, 1]), Data()])
func an_alert_that_is_not_on_or_off_is_refused(data: Data) {
    var g = gate(ours)
    _ = g.heard(info: info(ours, true))
    let r6 = g.alert(data)
    #expect(r6 == nil)
    #expect(g.faults.faults.first?.kind == .badAlertByte)
}

/// A new link proves nothing, so the last connection's proof is not carried over.
@Test func each_new_connection_must_prove_itself_again() {
    var g = gate(ours)
    _ = g.heard(info: info(ours, true))
    g.connected()
    #expect(g.listening == false)
}
