import CoreBluetooth

/// RingLink is CoreBluetooth behind RingRadio: it moves bytes and judges nothing, because every
/// decision is RingGate's and is tested without a radio.
final class RingLink: NSObject, RingRadio {
    static let service = CBUUID(string: "12345678-1234-1234-1234-123456789abc")
    static let emergency = CBUUID(string: "87654321-4321-4321-4321-cba987654321")
    static let deviceInfo = CBUUID(string: "11111111-2222-3333-4444-555555555555")
    static let restoreKey = "siren-ring-central"
    static let refuseMax = 8

    weak var events: RingRadioEvents?
    var ring: CBPeripheral?
    var alerts: CBCharacteristic?
    var info: CBCharacteristic?
    var userLeft = false
    var refused: [UUID] = []
    lazy var central = CBCentralManager(
        delegate: self, queue: nil,
        options: [CBCentralManagerOptionRestoreIdentifierKey: Self.restoreKey])

    /// init starts the central at once, so iOS can hand back a ring it kept while the app was dead.
    override init() {
        super.init()
        _ = central
    }

    /// scan asks only for the SIREN service, the one search iOS still runs in the background.
    func scan() {
        guard central.state == .poweredOn else { return }
        central.scanForPeripherals(withServices: [Self.service])
    }

    /// reconnect leaves a standing connect with iOS, which never times out, or scans if no ring
    /// is known yet.
    func reconnect() {
        guard let ring, central.state == .poweredOn else { return scan() }
        central.connect(ring)
    }

    /// drop ends the link and remembers whether the user asked, for lost().
    func drop(byUser: Bool) {
        userLeft = byUser
        if let ring { central.cancelPeripheralConnection(ring) }
    }

    /// refuse drops the ring and skips it for the rest of the session, oldest first out.
    func refuse() {
        guard let ring else { return }
        if refused.count >= Self.refuseMax { refused.removeFirst() }
        refused.append(ring.identifier)
        drop(byUser: false)
    }

    /// listen subscribes to alerts; iOS confirms each indication by itself.
    func listen() {
        guard let ring, let alerts else { return }
        ring.setNotifyValue(true, for: alerts)
    }

    /// tellRegistered writes exactly "true" or "false", the only registration answers the ring accepts.
    func tellRegistered(_ registered: Bool) {
        guard let ring, let info else { return }
        ring.writeValue(Data((registered ? "true" : "false").utf8), for: info, type: .withResponse)
    }

#if DEBUG
    /// sound writes "sound", which the ring obeys from the phone listening for its alarm; the
    /// alarm then comes back as an alert, as a press would.
    func sound() {
        guard let ring, let info else { return }
        ring.writeValue(Data("sound".utf8), for: info, type: .withResponse)
    }
#endif

    /// forgetLink clears what belonged to the last connection, keeping the ring to reconnect.
    func forgetLink() {
        alerts = nil
        info = nil
    }
}
