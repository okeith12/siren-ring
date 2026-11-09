#if DEBUG
import SwiftUI

/// SimRingPanel is the pretend ring's buttons, shown only with SIREN_ENV=sim: bring a ring in
/// range, press it, or walk it out of range.
struct SimRingPanel: View {
    static let ringA = "5a83ccfcefc611"
    static let ringB = "0b1c2d3e4f5a6b"
    let ring: SimRing

    /// body is which ring is in range on top, and what it does below.
    var body: some View {
        GroupBox("Pretend ring (SIREN_ENV=sim)") {
            HStack {
                button("A new") { ring.place("\(Self.ringA),false") }
                button("A registered") { ring.place("\(Self.ringA),true") }
                button("B registered") { ring.place("\(Self.ringB),true") }
                button("Not ready") { ring.place("notready,false") }
            }
            HStack {
                button("Press") { ring.press(true) }
                button("Release") { ring.press(false) }
                button("Walk away") { ring.away(true) }
                button("Come back") { ring.away(false) }
            }
        }
        .padding(.horizontal)
    }

    /// button is one small panel button.
    private func button(_ title: String, _ act: @escaping () -> Void) -> some View {
        Button(title, action: act)
            .buttonStyle(.bordered)
            .font(.caption2)
            .frame(maxWidth: .infinity)
    }
}
#endif
