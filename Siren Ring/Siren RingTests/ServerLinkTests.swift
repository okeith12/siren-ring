// The app talks to the SIREN server only through ServerLink, and believes only vetted answers.
import Foundation
import RingCore
import Testing
@testable import Siren_Ring

/// FakeServer keeps every request and answers as the test says the server would.
final class FakeServer: ServerLink {
    var asked: [String] = []
    var bodies: [Data?] = []
    let status: Int
    let answer: Data?

    /// init sets the status and answer every request gets.
    init(status: Int, answer: String = "") {
        self.status = status
        self.answer = Data(answer.utf8)
    }

    /// send keeps the request and answers at once.
    func send(_ path: String, _ body: Data?, done: @escaping (Int, Data?) -> Void) {
        asked.append(path)
        bodies.append(body)
        done(status, answer)
    }
}

/// Registering posts the ring to register-device and reports whether the server took it.
@Test func registering_posts_the_ring_and_reports_what_the_server_said() throws {
    for (status, took) in [(200, true), (500, false), (0, false)] {
        let server = FakeServer(status: status)
        var answer: Bool?
        RingRegistration(server: server).register(sirenId: ours, user: "Me", name: "Ring") { answer = $0 }
        #expect(server.asked == ["/api/register-device"])
        let body = try #require(server.bodies.first ?? nil)
        #expect(String(decoding: body, as: UTF8.self).contains(#""device_id":"\#(ours)""#))
        #expect(answer == took)
    }
}

/// Attack: a share code that is not six digits never reaches the server.
@Test func a_share_code_that_is_not_six_digits_never_reaches_the_server() {
    let server = FakeServer(status: 200)
    var found: ContactCard?
    for code in ["12345", "123456&x=1", "../../a", ""] {
        ContactManager.lookup(code, server: server) { found = $0 }
    }
    #expect(server.asked.isEmpty)
    #expect(found == nil)
}

/// A contact is believed only from a successful, vetted answer.
@Test func a_contact_is_believed_only_from_a_vetted_answer() {
    let good = #"{"success":true,"data":{"name":"Mom","device_id":"\#(theirs)","has_app":true}}"#
    let bad = #"{"success":true,"data":{"name":"Mom","device_id":"x","has_app":true}}"#
    var cards: [ContactCard?] = []
    for server in [FakeServer(status: 200, answer: good), FakeServer(status: 404, answer: good),
                   FakeServer(status: 200, answer: bad)] {
        ContactManager.lookup("042917", server: server) { cards.append($0) }
        #expect(server.asked == ["/api/auth-code?code=042917"])
    }
    #expect(cards.map { $0?.sirenId } == [theirs, nil, nil])
}
