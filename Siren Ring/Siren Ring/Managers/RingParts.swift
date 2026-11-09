import Foundation

/// RingParts is the radio and server the app runs on. A debug build launched with SIREN_ENV=sim
/// gets the pretend ring, and the pretend server too unless SIREN_SERVER points at a real one,
/// so the app can be walked through with no ring; a release build has only the real ones.
enum RingParts {
    static let home = "http://Perco-2.local:8080"  // the Mac running sirenserv, by its Bonjour name
#if DEBUG
    static let env = ProcessInfo.processInfo.environment
    static let pretend = env["SIREN_ENV"] == "sim"
    static let server = env["SIREN_SERVER"] ?? home
    static let radio: RingRadio = pretend ? SimRing.shared : RingLink()
    static let registration: RingRegistering =
        pretend && env["SIREN_SERVER"] == nil ? SimRegistration() : RingRegistration()
#else
    static let pretend = false
    static let server = home
    static let radio: RingRadio = RingLink()
    static let registration: RingRegistering = RingRegistration()
#endif
}
