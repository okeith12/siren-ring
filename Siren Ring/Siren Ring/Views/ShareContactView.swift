import SwiftUI

/// View for generating authentication codes to share with emergency contact requesters
struct ShareContactView: View {
    @StateObject private var authManager = ContactManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showingCopiedAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 15) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Share Emergency Contact")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Generate a code for someone to add you as their emergency contact")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if authManager.isCodeActive {
                    VStack(spacing: 20) {
                        VStack(spacing: 10) {
                            Text("Your Code")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(authManager.currentCode)
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(15)
                        }
                        
                        if let expirationDate = authManager.expirationDate {
                            Text("Expires: \(expirationDate, style: .timer)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        HStack(spacing: 15) {
                            Button("Copy Code") {
                                UIPasteboard.general.string = authManager.currentCode
                                showingCopiedAlert = true
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Cancel Code") {
                                authManager.cancelAuthCode()
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Button("Generate Code") {
                            let _ = authManager.generateAuthCode()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        VStack(spacing: 10) {
                            Text("How it works:")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Code expires in 10 minutes", systemImage: "clock")
                                Label("Share code with the person", systemImage: "square.and.arrow.up")
                                Label("They tap 'Add' and enter your code", systemImage: "person.badge.plus")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Share Contact")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert("Code Copied", isPresented: $showingCopiedAlert) {
                Button("OK") { }
            } message: {
                Text("The authentication code has been copied to your clipboard")
            }
        }
    }
}