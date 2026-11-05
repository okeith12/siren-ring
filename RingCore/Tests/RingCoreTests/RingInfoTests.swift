// What a ring says about itself: only "sirenId,true|false" with a real Siren id is believed.
import Foundation
import Testing
@testable import RingCore

/// bytes turns text into what the radio hands the app.
private func bytes(_ text: String) -> Data { Data(text.utf8) }

/// Case 1: an unregistered ring reads as its id, not registered.
@Test func a_ring_that_is_not_registered_reads_as_its_id_and_false() {
    #expect(RingInfo.parse(bytes("5a83ccfcefc611,false"))
        == RingInfo(sirenId: "5a83ccfcefc611", registered: false))
}

/// Case 2: a registered ring reads as its id, registered.
@Test func a_registered_ring_reads_as_its_id_and_true() {
    #expect(RingInfo.parse(bytes("5a83ccfcefc611,true"))
        == RingInfo(sirenId: "5a83ccfcefc611", registered: true))
}

/// Case 3: a ring with no id yet can never be registered under "notready".
@Test func a_ring_with_no_id_yet_is_refused() {
    #expect(RingInfo.parse(bytes("notready,false")) == nil)
}

/// Cases 4 and 5: only the ring's own id shape is an id.
@Test(arguments: ["5a83ccfcefc61", "5a83ccfcefc6111", "5A83CCFCEFC611", "5a83ccfcefc61z", ""])
func an_id_that_is_not_fourteen_lowercase_hex_is_refused(id: String) {
    #expect(RingInfo.parse(bytes("\(id),true")) == nil)
}

/// Case 6: registration is only ever the exact words true or false.
@Test(arguments: ["yes", "TRUE", "", "1"])
func a_registration_other_than_true_or_false_is_refused(word: String) {
    #expect(RingInfo.parse(bytes("5a83ccfcefc611,\(word)")) == nil)
}

/// Case 7: the answer has exactly two fields.
@Test(arguments: ["5a83ccfcefc611", ",true", "5a83ccfcefc611,true,x", "5a83ccfcefc611,,true"])
func an_answer_without_exactly_two_fields_is_refused(text: String) {
    #expect(RingInfo.parse(bytes(text)) == nil)
}

/// Case 8: nothing, broken text, or more than a ring ever sends is refused.
@Test func empty_broken_or_oversized_data_is_refused() {
    #expect(RingInfo.parse(nil) == nil)
    #expect(RingInfo.parse(Data()) == nil)
    #expect(RingInfo.parse(Data([0xFF, 0xFE, 0x2C, 0x74])) == nil)
    #expect(RingInfo.parse(Data(repeating: 0x61, count: 512)) == nil)
}
