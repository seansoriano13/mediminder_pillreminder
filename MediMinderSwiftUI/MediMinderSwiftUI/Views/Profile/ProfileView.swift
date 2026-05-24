import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService

    @State private var isSigningOut = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let purple = Color(red: 0.404, green: 0.314, blue: 0.643)

    var user: User? { authService.currentUser }
    var displayName: String { user?.displayName ?? user?.email ?? "User" }
    var initial: String { String(displayName.prefix(1)).uppercased() }

    var body: some View {
        NavigationStack {
            List {
                // ── Avatar ────────────────────────────────────────────────
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(purple.opacity(0.2))
                                    .frame(width: 96, height: 96)
                                Text(initial)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(purple)
                            }
                            Text(displayName)
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // ── Account Info ──────────────────────────────────────────
                Section("Account") {
                    infoRow(icon: "envelope", label: "Email",
                            value: user?.email ?? "—")

                    infoRow(icon: "person.badge.key", label: "Account ID",
                            value: (user?.uid.prefix(12).description ?? "") + "…")

                    infoRow(icon: "checkmark.shield", label: "Sign-in Method",
                            value: signInMethod)
                }

                // ── Sign Out ──────────────────────────────────────────────
                Section {
                    Button(action: signOut) {
                        HStack {
                            Spacer()
                            if isSigningOut {
                                ProgressView()
                            } else {
                                Label("Sign Out", systemImage: "arrow.right.square")
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSigningOut)
                }
            }
            .navigationTitle("Profile")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func infoRow(icon: String, label: String, value: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .fontWeight(.medium)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundColor(purple)
        }
    }

    var signInMethod: String {
        guard let provider = user?.providerData.first?.providerID else { return "Unknown" }
        if provider == "google.com" { return "Google" }
        if provider == "password"   { return "Email & Password" }
        return provider
    }

    private func signOut() {
        isSigningOut = true
        do {
            try authService.signOut()
        } catch {
            errorMessage = "Sign-out failed: \(error.localizedDescription)"
            showError = true
            isSigningOut = false
        }
    }
}
