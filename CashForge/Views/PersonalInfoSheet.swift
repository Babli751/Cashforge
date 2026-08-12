import SwiftUI

struct PersonalInfoSheet: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var info = PersonalInfo()
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?

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
                if case .success(let fetched) = await service.fetchDetailed(token: token) {
                    info = fetched
                }
                isLoading = false
            }
        }
    }

    private func field(_ label: String, text: Binding<String>, contentType: UITextContentType, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            TextField(label, text: text)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .padding(12)
                .background(Theme.card(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundColor(Theme.text(colorScheme))
        }
    }
}
