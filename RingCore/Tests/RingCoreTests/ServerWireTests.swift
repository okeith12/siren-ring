// What the app sends the SIREN server, and which of the server's answers the app believes.
import Foundation
import Testing
@testable import RingCore

/// sent reads a request body back the way the server sees it.
private func sent(_ data: Data?) throws -> NSDictionary {
    let data = try #require(data)
    return try #require(JSONSerialization.jsonObject(with: data) as? NSDictionary)
}

/// answer turns server text into the bytes the network hands the app.
private func answer(_ text: String) -> Data { Data(text.utf8) }

/// A registration carries the ring, its owner, and this phone's push token.
@Test func a_registration_carries_the_ring_its_owner_and_the_push_token() throws {
    let body = try sent(ServerWire.body(Registration(
        deviceId: "5a83ccfcefc611", userId: "Me", deviceName: "My Ring", apnsToken: "")))
    #expect(body == ["device_id": "5a83ccfcefc611", "user_id": "Me",
                     "device_name": "My Ring", "apns_token": ""])
}

/// An emergency names each contact by their ring, so the server knows whom to push.
@Test func an_emergency_names_each_contact_by_their_ring() throws {
    let body = try sent(ServerWire.body(Emergency(
        userId: "5a83ccfcefc611", message: "help", timestamp: "2026-11-09T12:00:00Z",
        contacts: [Alerted(name: "Mom", phone: "", deviceId: "0b1c2d3e4f5a6b")])))
    #expect(body == ["emergency_type": "siren_ring_activation", "priority": "critical",
                     "user_id": "5a83ccfcefc611", "message": "help",
                     "timestamp": "2026-11-09T12:00:00Z",
                     "contacts": [["name": "Mom", "phone": "", "device_id": "0b1c2d3e4f5a6b"]]])
}

/// A code request and a token update carry the fields the server reads.
@Test func a_code_request_and_a_token_update_carry_what_the_server_reads() throws {
    let code = try sent(ServerWire.body(CodeRequest(
        deviceId: "5a83ccfcefc611", deviceName: "SIREN Ring", userId: "Me", expiresIn: 10)))
    #expect(code == ["device_id": "5a83ccfcefc611", "device_name": "SIREN Ring",
                     "user_id": "Me", "expires_in": 10])
    let token = try sent(ServerWire.body(TokenUpdate(
        deviceId: "5a83ccfcefc611", apnsToken: "abc", userId: "5a83ccfcefc611")))
    #expect(token == ["device_id": "5a83ccfcefc611", "apns_token": "abc",
                      "user_id": "5a83ccfcefc611"])
}

/// A code the server issued is taken from a successful answer.
@Test func an_issued_code_is_taken_from_a_successful_answer() {
    #expect(ServerAnswer.code(answer(#"{"success":true,"data":{"code":"042917"}}"#)) == "042917")
}

/// Attack: a server or a man in the middle hands back a code that is not six plain digits.
@Test(arguments: ["12345", "1234567", "12a456", "", "١٢٣٤٥٦", "12 456"])
func a_code_that_is_not_six_plain_digits_is_refused(code: String) {
    #expect(ServerAnswer.code(answer(#"{"success":true,"data":{"code":"\#(code)"}}"#)) == nil)
}

/// A failed, broken, missing or oversized answer gives no code.
@Test(arguments: [#"{"success":false,"data":{"code":"042917"}}"#, #"{"success":true}"#,
                  "not json", "", #"{"success":true,"data":{"code":"042917","x":""#
                    + String(repeating: "a", count: 4096) + #""}}"#])
func a_failed_broken_or_oversized_answer_gives_no_code(text: String) {
    #expect(ServerAnswer.code(answer(text)) == nil)
    #expect(ServerAnswer.code(nil) == nil)
}

/// A contact found by code is taken from a successful answer.
@Test func a_contact_found_by_code_is_taken_from_a_successful_answer() {
    let text = #"{"success":true,"data":{"name":"Mom","device_id":"0b1c2d3e4f5a6b","has_app":true}}"#
    #expect(ServerAnswer.contact(answer(text))
        == ContactCard(name: "Mom", sirenId: "0b1c2d3e4f5a6b", hasApp: true))
}

/// Attack: a contact whose ring id is not a Siren id, or whose name is empty or huge, is refused.
@Test(arguments: [("Mom", "../../etc"), ("", "0b1c2d3e4f5a6b"), ("   ", "0b1c2d3e4f5a6b"),
                  (String(repeating: "M", count: 65), "0b1c2d3e4f5a6b")])
func a_contact_with_a_bad_ring_or_name_is_refused(name: String, id: String) {
    let text = #"{"success":true,"data":{"name":"\#(name)","device_id":"\#(id)","has_app":true}}"#
    #expect(ServerAnswer.contact(answer(text)) == nil)
}
