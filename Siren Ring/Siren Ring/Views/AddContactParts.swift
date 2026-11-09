import SwiftUI

/// AddContactHeader is the top of Add Contact: what the screen is for.
struct AddContactHeader: View {
    /// body is the icon, the title and one line on what a contact gets.
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("Add Emergency Contact")
                .font(.title2)
                .fontWeight(.bold)
            Text("Add someone to receive your emergency alerts")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

/// ContactMethodsHelp explains the two ways to add a contact, with the code steps when the
/// code method is picked.
struct ContactMethodsHelp: View {
    let byCode: Bool

    /// body is the two methods, then the three code steps when they apply.
    var body: some View {
        VStack(spacing: 10) {
            Text("Contact Methods:")
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                Label("Phone: Receives SMS emergency alerts", systemImage: "phone.fill")
                    .foregroundColor(.orange)
                Label("App Code: Full SIREN app integration", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                if byCode {
                    Divider()
                    Label("Ask them to open SIREN app", systemImage: "1.circle")
                    Label("They tap 'Share Contact Info'", systemImage: "2.circle")
                    Label("Enter their 6-digit code above", systemImage: "3.circle")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

/// CodeField is where a share code is typed; it holds six characters at most, the length of
/// every code the server makes.
struct CodeField: View {
    @Binding var code: String

    /// body is the label and a large, centered number field.
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Authentication Code")
                .font(.headline)
            TextField("000000", text: $code)
                .font(.system(size: 24, weight: .medium, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .onChange(of: code) { _, typed in
                    if typed.count > 6 { code = String(typed.prefix(6)) }
                }
        }
    }
}
