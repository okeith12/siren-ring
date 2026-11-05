import SwiftUI

/// RingConnectedCard slides up when a ring pairs itself, the way AirPods announce themselves,
/// so the user knows which ring the phone is now listening to.
struct RingConnectedCard: View {
    let sirenId: String
    @Environment(\.dismiss) private var dismiss

    /// body is the half-height card: the ring, its short id, and Done.
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            Text("SIREN Ring Connected")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Ring \(String(sirenId.prefix(6))) is now yours and listening for alerts.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
        .presentationDetents([.medium])
    }
}
