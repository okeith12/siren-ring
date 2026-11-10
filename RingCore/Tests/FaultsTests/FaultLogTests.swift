// The fault log keeps what the app refused, in fixed room, without ever stopping the app.
import Foundation
import Testing
@testable import Faults

private let noon = Date(timeIntervalSince1970: 43_200)

/// A fault keeps its kind, its time and no more than the first eight bytes of what was refused.
@Test func a_fault_keeps_its_kind_time_and_the_first_eight_bytes() {
    var log = FaultLog()
    log.record(.badRingInfo, Array(0..<20), at: noon)
    #expect(log.faults == [Fault(kind: .badRingInfo, at: noon, bytes: Array(0..<8))])
}

/// A full log counts what it cannot hold, so it never grows.
@Test func the_log_holds_sixteen_and_counts_the_rest_as_dropped() {
    var log = FaultLog()
    for _ in 0..<20 { log.record(.badAlertByte, at: noon) }
    #expect(log.faults.count == 16)
    #expect(log.dropped == 4)
}

/// A failed check is recorded with its site and reports false, so the caller takes the safe path.
@Test func a_failed_check_is_recorded_with_its_site_and_reports_false() {
    var log = FaultLog()
    let r1 = log.check(false, site: 7, at: noon)
    #expect(r1 == false)
    #expect(log.faults == [Fault(kind: .assertFailed, at: noon, bytes: [7])])
}

/// A passing check costs nothing in the log.
@Test func a_passing_check_records_nothing() {
    var log = FaultLog()
    let r2 = log.check(true, site: 7)
    #expect(r2 == true)
    #expect(log.faults.isEmpty)
}

/// The log survives the app being killed, because the app saves and loads it as data.
@Test func the_log_comes_back_the_same_after_saving() throws {
    var log = FaultLog()
    log.record(.alertNotListened, [1], at: noon)
    let back = try JSONDecoder().decode(FaultLog.self, from: JSONEncoder().encode(log))
    #expect(back.faults == log.faults)
    #expect(back.dropped == log.dropped)
}

/// Attack: a saved log edited to hold more than sixteen keeps sixteen and counts the rest, so
/// storage can never make the log grow.
@Test func a_saved_log_with_more_than_sixteen_keeps_sixteen_and_counts_the_rest() throws {
    let one = #"{"kind":0,"at":0,"bytes":[]}"#
    let text = #"{"dropped":1,"faults":["# + Array(repeating: one, count: 20).joined(separator: ",") + "]}"
    let log = try JSONDecoder().decode(FaultLog.self, from: Data(text.utf8))
    #expect(log.faults.count == 16)
    #expect(log.dropped == 5)
}
