import Foundation

/// ContactCard is a contact the server found by share code, vetted before the app keeps it.
public struct ContactCard: Equatable, Sendable {
    public let name: String
    public let sirenId: String
    public let hasApp: Bool
}

/// ServerAnswer reads what the server sends back. The network is untrusted, so an answer is
/// believed only when it is small, says success, and every field makes sense.
public enum ServerAnswer {
    public static let maxBytes = 2048
    public static let maxNameBytes = 64
    public static let codeLength = 6

    /// code is the share code from an answer, only if it is exactly six plain digits.
    public static func code(_ data: Data?) -> String? {
        guard let issued: Issued = opened(data), isCode(issued.code) else { return nil }
        return issued.code
    }

    /// contact is the contact from an answer, only with a real Siren id and a sane name.
    public static func contact(_ data: Data?) -> ContactCard? {
        guard let found: Found = opened(data) else { return nil }
        let name = found.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.utf8.count <= maxNameBytes, RingInfo.isSirenId(found.deviceId)
        else { return nil }
        return ContactCard(name: name, sirenId: found.deviceId, hasApp: found.hasApp)
    }

    /// isCode accepts exactly six ASCII digits, the only codes the server makes.
    public static func isCode(_ text: some StringProtocol) -> Bool {
        text.utf8.count == codeLength && text.utf8.allSatisfy { (0x30...0x39).contains($0) }
    }

    /// opened decodes a successful answer's data, or nil for anything too big, failed or broken.
    private static func opened<T: Decodable>(_ data: Data?) -> T? {
        guard let data, data.count <= maxBytes else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let envelope = try? decoder.decode(Envelope<T>.self, from: data), envelope.success
        else { return nil }
        return envelope.data
    }
}

/// Envelope is the server's answer shape: {success, data}.
private struct Envelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
}

/// Issued is the data of a share code answer.
private struct Issued: Decodable {
    let code: String
}

/// Found is the data of a contact lookup answer.
private struct Found: Decodable {
    let name: String
    let deviceId: String
    let hasApp: Bool
}
