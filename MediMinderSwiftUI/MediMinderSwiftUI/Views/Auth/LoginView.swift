import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var isSecure = true
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSignup = false

    private let purple = Color(red: 0.404, green: 0.314, blue: 0.643)

    var body: some View {
        ZStack {
            // Atmospheric background blob (mirrors Flutter's _AtmosphericBlob)
            GeometryReader { geo in
                Circle()
                    .fill(purple.opacity(0.18))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: geo.size.width - 80, y: -80)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 60)

                    // ── Header ────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 16) {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(purple.opacity(0.2))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "pills.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(purple)
                            )

                        Text("MediMinder")
                            .font(.system(size: 34, weight: .bold))

                        Text("Your personal medication companion.")
                            .foregroundColor(.secondary)
                            .font(.body)
                    }
                    .padding(.bottom, 40)

                    // ── Form ──────────────────────────────────────────
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        HStack {
                            if isSecure {
                                SecureField("Password", text: $password)
                            } else {
                                TextField("Password", text: $password)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                            Button(action: { isSecure.toggle() }) {
                                Image(systemName: isSecure ? "eye" : "eye.slash")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.bottom, 24)

                    // ── Sign In Button ────────────────────────────────
                    Button(action: signIn) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 50)
                                .fill(isLoading ? purple.opacity(0.6) : purple)
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(height: 54)
                    }
                    .disabled(isLoading)
                    .padding(.bottom, 32)

                    // ── Sign Up Prompt ────────────────────────────────
                    HStack {
                        Spacer()
                        Text("Don't have an account? ")
                            .foregroundColor(.secondary)
                        Button("Sign Up") {
                            showSignup = true
                        }
                        .foregroundColor(purple)
                        .fontWeight(.bold)
                        Spacer()
                    }
                }
                .padding(.horizontal, 28)
            }
        }
        .sheet(isPresented: $showSignup) {
            SignupView()
                .environmentObject(authService)
        }
        .alert("Sign-in Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Actions

    private func signIn() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            showError = true
            return
        }

        isLoading = true
        Task {
            do {
                try await authService.signIn(email: trimmedEmail, password: password)
            } catch {
                await MainActor.run {
                    errorMessage = friendlyError(error.localizedDescription)
                    showError = true
                }
            }
            await MainActor.run { isLoading = false }
        }
    }

    private func friendlyError(_ raw: String) -> String {
        let lower = raw.lowercased()
        if lower.contains("user not found") || lower.contains("no user") {
            return "No account found with this email."
        } else if lower.contains("password") {
            return "Incorrect password. Please try again."
        } else if lower.contains("email") {
            return "Please enter a valid email address."
        }
        return "Sign-in failed. Please try again."
    }
}
