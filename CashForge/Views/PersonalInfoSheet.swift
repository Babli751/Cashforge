import SwiftUI

struct PersonalInfoSheet: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var info = PersonalInfo()
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    @State private var originalEmail = ""
    @State private var newEmail = ""
    @State private var newPassword = ""
    @State private var currentPassword = ""
    @State private var credentialMessage: String?
    @State private var credentialSuccess = false
    @State private var isSavingCredentials = false

    private let service = ProfileInfoService()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background(colorScheme).ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(Theme.gold(colorScheme))
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            field("Full Name", text: $info.fullName, contentType: .name)
                            field("Phone Number", text: $info.phoneNumber, contentType: .telephoneNumber, keyboard: .phonePad)
                            field("Address", text: $info.addressLine, contentType: .streetAddressLine1)
                            field("City", text: $info.city, contentType: .addressCity)
                            field("Country", text: $info.country, contentType: .countryName)

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(Theme.danger)
                            }

                            Divider().padding(.vertical, 8)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Account")
                                    .font(.headline)
                                    .foregroundColor(Theme.text(colorScheme))

                                field("Email", text: $newEmail, contentType: .emailAddress, keyboard: .emailAddress)
                                field("New Password (leave blank to keep current)", text: $newPassword, contentType: .newPassword, isSecure: true)
                                field("Current Password (required to save changes)", text: $currentPassword, contentType: .password, isSecure: true)

                                if let credentialMessage {
                                    Text(credentialMessage)
                                        .font(.caption)
                                        .foregroundColor(credentialSuccess ? Theme.success : Theme.danger)
                                }

                                Button {
                                    Task { await saveCredentials() }
                                } label: {
                                    if isSavingCredentials {
                                        ProgressView()
                                    } else {
                                        Text("Update Email / Password")
                                    }
                                }
                                .buttonStyle(GoldButtonStyle(outline: true))
                                .disabled(isSavingCredentials || currentPassword.isEmpty || (newEmail == originalEmail && newPassword.isEmpty))
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Personal Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            guard let token = authService.token else {
                                errorMessage = "Not signed in."
                                return
                            }
                            isSaving = true
                            let success = await service.save(info, token: token)
                            isSaving = false
                            if success {
                                authService.updatePersonalInfo(info)
                                dismiss()
                            } else {
                                errorMessage = "Could not save. Try again."
                            }
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .task {
                guard let token = authService.token else {
                    isLoading = false
                    return
                }
                if case .success(let email, let fetched) = await service.fetchDetailed(token: token) {
                    info = fetched
                    originalEmail = email
                    newEmail = email
                }
                isLoading = false
            }
        }
    }

    private func field(_ label: String, text: Binding<String>, contentType: UITextContentType, keyboard: UIKeyboardType = .default, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Group {
                if isSecure {
                    SecureField(label, text: text)
                } else {
                    TextField(label, text: text)
                }
            }
            .textContentType(contentType)
            .keyboardType(keyboard)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .padding(12)
            .background(Theme.card(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundColor(Theme.text(colorScheme))
        }
    }

    private func saveCredentials() async {
        guard let token = authService.token else {
            credentialMessage = "Not signed in."
            credentialSuccess = false
            return
        }
        isSavingCredentials = true
        defer { isSavingCredentials = false }

        if !newEmail.isEmpty && newEmail != originalEmail {
            let outcome = await service.updateEmail(newEmail: newEmail, currentPassword: currentPassword, token: token)
            switch outcome {
            case .success:
                authService.updateStoredEmail(newEmail)
                originalEmail = newEmail
            case .failure(let message):
                credentialMessage = message
                credentialSuccess = false
                return
            }
        }

        if !newPassword.isEmpty {
            let outcome = await service.updatePassword(newPassword: newPassword, currentPassword: currentPassword, token: token)
            if case .failure(let message) = outcome {
                credentialMessage = message
                credentialSuccess = false
                return
            }
        }

        credentialMessage = "Updated successfully."
        credentialSuccess = true
        newEmail = ""
        newPassword = ""
        currentPassword = ""
    }
}
