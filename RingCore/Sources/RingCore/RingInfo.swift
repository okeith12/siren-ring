import Foundation

/// RingInfo is what a ring says about itself in device info: its Siren id and whether it is
/// registered, as the ring writes it ("5a83ccfcefc611,true").
public struct RingInfo: Equatable, Sendable {
    public static let idLength = 14
    public static let maxLength = 24
    public let sirenId: String
    public let registered: Bool

    /// parse accepts only "sirenId,true|false"; anything else, including a ring that has no id
    /// yet ("notready,false"), is nil, so it never becomes an id the app trusts.
    public static func parse(_ data: Data?) -> RingInfo? {
        guard let data, data.count <= maxLength, let text = String(data: data, encoding: .utf8)
        else { return nil }
        let parts = text.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count == 2, isSirenId(parts[0]) else { return nil }
        switch parts[1] {
        case "true": return RingInfo(sirenId: String(parts[0]), registered: true)
        case "false": return RingInfo(sirenId: String(parts[0]), registered: false)
        default: return nil
        }
    }

    /// isSirenId accepts exactly what the ring makes: 14 lowercase hex characters.
    public static func isSirenId(_ text: some StringProtocol) -> Bool {
        text.utf8.count == idLength
            && text.utf8.allSatisfy { (0x30...0x39).contains($0) || (0x61...0x66).contains($0) }
    }
}
