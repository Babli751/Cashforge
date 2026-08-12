import SwiftUI

struct AuthSheet: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var mode: Mode = .login
    @State private var email = ""
    @State private var password = ""

    enum Mode: String, CaseIterable {
        case login = "Sign In"
        case register = "Register"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background(colorScheme).ignoresSafeArea()
                VStack(spacing: 20) {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top)

                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(Theme.card(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundColor(Theme.text(colorScheme))

                        SecureField(mode == .register ? "Password (min 8 characters)" : "Password", text: $password)
                            .textContentType(mode == .register ? .newPassword : .password)
                            .padding(12)
                            .background(Theme.card(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundColor(Theme.text(colorScheme))
                    }
                    .padding(.horizontal)

                    if let error = authService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(Theme.danger)
                            .padding(.horizontal)
                    }

                    Button {
                        Task {
                            if mode == .login {
                                await authService.login(email: email, password: password)
                            } else {
                                await authService.register(email: email, password: password)
                            }
                            if authService.isSignedIn { dismiss() }
                        }
                    } label: {
                        if authService.isWorking {
                            ProgressView().tint(.black)
                        } else {
                            Text(mode.rawValue)
                        }
                    }
                    .buttonStyle(GoldButtonStyle())
                    .disabled(authService.isWorking || email.isEmpty || password.isEmpty)
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle(mode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
