import Foundation

/// RingParts is the radio and server the app runs on. A debug build launched with SIREN_ENV=sim
/// gets the pretend ring and server, so the app can be walked through with no ring; a release
/// build has only the real ones.
enum RingParts {
#if DEBUG
    static let pretend = ProcessInfo.processInfo.environment["SIREN_ENV"] == "sim"
    static let radio: RingRadio = pretend ? SimRing.shared : RingLink()
    static let registration: RingRegistering = pretend ? SimRegistration() : RingRegistration()
#else
    static let pretend = false
    static let radio: RingRadio = RingLink()
    static let registration: RingRegistering = RingRegistration()
#endif
}
