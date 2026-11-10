// Only the paired ring, once it has proven who it is, can reach the family.
import Foundation
import Testing
@testable import Siren_Ring

/// The paired ring is listened to, and its alarm reaches the family.
@Test func the_paired_ring_is_listened_to_and_its_alarm_reaches_the_family() throws {
    let b = try Bench(paired: ours)
    b.connect("\(ours),true")
    #expect(b.radio.listens == 1)
    b.manager.heardAlert(Data([1]))
    #expect(b.alerts.ons == 1)
    #expect(b.manager.emergencyActive)
    b.manager.heardAlert(Data([0]))
    #expect(b.alerts.offs == 1)
}

/// Attack: a stranger named SIREN-Ring sends 1; nobody is alerted and it is turned away.
@Test func a_stranger_ring_never_raises_the_alarm() throws {
    let b = try Bench(paired: ours)
    b.connect("\(theirs),true")
    b.manager.heardAlert(Data([1]))
    #expect(b.alerts.ons == 0)
    #expect(b.radio.listens == 0)
    #expect(b.radio.refusals == 1)
}

/// Attack: an alarm sent before the ring has said who it is reaches nobody.
@Test func an_alarm_before_the_ring_proves_itself_is_ignored() throws {
    let b = try Bench(paired: ours)
    b.manager.linked()
    b.manager.heardAlert(Data([1]))
    #expect(b.alerts.ons == 0)
}

/// Like AirPods: a registered ring met with no pairing becomes ours and says so.
@Test func a_registered_ring_met_with_no_pairing_pairs_itself_and_says_so() throws {
    let b = try Bench()
    b.connect("\(ours),true")
    #expect(b.pairing == ours)
    #expect(b.manager.newRing == ours)
    #expect(b.alerts.pairedIds == [ours])
    #expect(b.radio.listens == 1)
}

/// A ring with no id yet is shown as not ready and can never be registered as "notready".
@Test func a_ring_with_no_id_yet_offers_no_registration() throws {
    let b = try Bench()
    b.connect("notready,false")
    #expect(b.manager.showRegistrationButton == false)
    #expect(b.manager.deviceUUID == "")
    #expect(b.manager.connectionStatus == "SIREN Ring not ready")
}

/// A ring nobody registered is offered for Register, and not listened to until then.
@Test func an_unregistered_ring_offers_registration_and_is_not_listened_to() throws {
    let b = try Bench()
    b.connect("\(ours),false")
    #expect(b.manager.showRegistrationButton)
    #expect(b.manager.deviceUUID == ours)
    #expect(b.radio.listens == 0)
}

/// Registering pairs the ring, tells it so, and starts listening.
@Test func registering_a_ring_pairs_it_and_starts_listening() throws {
    let b = try Bench(accepts: true)
    b.connect("\(ours),false")
    b.manager.registerDevice()
    #expect(b.radio.told == [true])
    #expect(b.pairing == ours)
    #expect(b.radio.listens == 1)
}

/// A server that refuses leaves the ring unregistered and unpaired.
@Test func a_refused_registration_pairs_nothing() throws {
    let b = try Bench(accepts: false)
    b.connect("\(ours),false")
    b.manager.registerDevice()
    #expect(b.radio.told == [false])
    #expect(b.pairing == nil)
    #expect(b.radio.listens == 0)
}

/// What the app refused is still on record after the app is killed and started again.
@Test func refusals_survive_the_app_being_killed() throws {
    let first = try Bench(paired: ours)
    first.connect("\(theirs),true")
    first.manager.heardAlert(Data([1]))
    let again = try Bench(store: first.store)
    #expect(again.manager.faultCount >= 1)
}

/// A saved log that will not load is replaced, and the loss itself is recorded.
@Test func a_corrupt_saved_log_is_replaced_and_the_loss_recorded() throws {
    let store = try #require(UserDefaults(suiteName: "bench-\(UUID().uuidString)"))
    store.set(Data("not a log".utf8), forKey: RingStore.faultsKey)
    let b = try Bench(store: store)
    #expect(b.manager.faultCount == 1)
}

/// An alarm notification iOS would not show is recorded, not lost.
@Test func a_notification_that_never_shows_is_recorded() throws {
    let b = try Bench(paired: ours)
    b.manager.alertFailed()
    #expect(b.manager.faultCount == 1)
}

/// A ring is shown ready only once it proves it is ours: not while it is checked, not when it
/// is not ready, and not after it drops.
@Test func only_the_proven_ring_is_shown_ready() throws {
    let b = try Bench(paired: ours)
    b.manager.linked()
    #expect(!b.manager.ringReady)
    b.manager.heardInfo(Data("notready,false".utf8))
    #expect(!b.manager.ringReady)
    b.connect("\(ours),true")
    #expect(b.manager.ringReady)
    b.manager.lost(userLeft: false)
    #expect(!b.manager.ringReady)
}
