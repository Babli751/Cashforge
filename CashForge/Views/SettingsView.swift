import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var showResetConfirm = false
    @State private var showAuthSheet = false
    @State private var showManageSubscriptions = false
    @State private var showPersonalInfo = false

    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.dark.rawValue
    private var appTheme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: appThemeRaw) ?? .dark },
            set: { appThemeRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background(colorScheme).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        if !authService.isSignedIn {
                            accountSection
                        }

                        section("Preferences") {
                            row {
                                Text("Appearance")
                                    .foregroundColor(Theme.text(colorScheme))
                                Spacer()
                                Picker("Appearance", selection: appTheme) {
                                    ForEach(AppTheme.allCases) { theme in
                                        Label(theme.rawValue, systemImage: theme.icon).tag(theme)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Theme.gold(colorScheme))
                            }

                            if authService.isSignedIn {
                                divider
                                navRow("Personal Info") { showPersonalInfo = true }
                            }
                        }

                        section("Billing") {
                            navRow("Manage Subscription") { showManageSubscriptions = true }
                        }

                        section("Business") {
                            Button("Reset Current Business") { showResetConfirm = true }
                                .buttonStyle(GoldButtonStyle(outline: true))
                                .padding(12)
                        }

                        if authService.isSignedIn {
                            Button("Sign Out") {
                                authService.signOut()
                                store.refreshUnlockState()
                                dismiss()
                            }
                            .buttonStyle(GoldButtonStyle(outline: true))
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.vertical)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Reset business?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.business = BusinessState()
                }
            } message: {
                Text("This clears your current progress and starts a new business.")
            }
            .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
            .sheet(isPresented: $showAuthSheet) {
                AuthSheet()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showPersonalInfo) {
                PersonalInfoSheet()
                    .environmentObject(authService)
            }
            .task(id: authService.isSignedIn) {
                if authService.isSignedIn {
                    await store.syncAfterSignIn()
                }
            }
        }
    }

    @ViewBuilder
    private var accountSection: some View {
        section("Account") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Playing as guest. Sign in or create an account to save your progress.")
                    .font(.caption)
                    .foregroundColor(.gray)
                Button("Sign In / Register") {
                    showAuthSheet = true
                }
                .buttonStyle(GoldButtonStyle())
            }
            .padding(12)
        }
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(Theme.gold(colorScheme))
                .padding(.horizontal, 16)
            VStack(spacing: 0) {
                content()
            }
            .background(Theme.card(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            .padding(.horizontal)
        }
    }

    private func row<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack {
            content()
        }
        .padding(12)
    }

    private func navRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(Theme.text(colorScheme))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(12)
        }
    }

    private var divider: some View {
        Divider().background(Color.gray.opacity(0.3)).padding(.leading, 12)
    }
}
