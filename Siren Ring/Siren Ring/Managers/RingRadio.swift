import Foundation

/// RingRadioEvents is what the radio hears; RingLink calls these on the main queue, unvetted.
protocol RingRadioEvents: AnyObject {
    /// ready reports Bluetooth on, so the app can go and find its ring.
    func ready()
    /// linked reports a ring connecting; nothing about it is proven yet.
    func linked()
    /// lost reports the link going; userLeft is true only when the user ended it.
    func lost(userLeft: Bool)
    /// heardInfo hands over the ring's device info exactly as it arrived.
    func heardInfo(_ data: Data?)
    /// heardAlert hands over an emergency value exactly as it arrived.
    func heardAlert(_ data: Data?)
}

/// RingRadio is the phone's Bluetooth link to a ring, behind a protocol so tests can stand in
/// for CoreBluetooth.
protocol RingRadio: AnyObject {
    var events: RingRadioEvents? { get set }
    /// scan looks for rings advertising the SIREN service, which iOS allows in the background.
    func scan()
    /// reconnect asks iOS to connect the last ring whenever it is back in range, with no timeout.
    func reconnect()
    /// drop ends the link; byUser says whether the user asked for it.
    func drop(byUser: Bool)
    /// refuse drops the connected ring and never connects to it again this session.
    func refuse()
    /// listen subscribes to the proven ring's alerts.
    func listen()
    /// tellRegistered writes the registration answer to the ring.
    func tellRegistered(_ registered: Bool)
#if DEBUG
    /// sound asks the ring to sound, to prove the app reaches the ring.
    func sound()
#endif
}

/// RingAlerting is what the app does once the proven ring speaks.
protocol RingAlerting {
    /// on tells the family the alarm is sounding.
    func on()
    /// off tells the user the alarm stopped.
    func off()
    /// paired tells the user, like AirPods, that a ring is now theirs.
    func paired(_ sirenId: String)
}

/// RingRegistering registers a ring with the server and answers whether the server took it.
protocol RingRegistering {
    /// register sends the ring and its owner to the server; done runs on the main queue.
    func register(sirenId: String, user: String, name: String, done: @escaping (Bool) -> Void)
}
