import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    policySection(
                        title: "Data Stored",
                        text: "SmartSpend stores the expenses, categories, budgets, monthly salary values, recurring expenses, deleted expenses, and preferences you add in the app."
                    )

                    policySection(
                        title: "Local First",
                        text: "Your data stays on your device. The iOS widget reads shared app data through Apple's App Group storage so it can show your spending summary."
                    )

                    policySection(
                        title: "Imports and Exports",
                        text: "CSV imports are processed on your device. Export files are created only when you choose to export your data."
                    )

                    policySection(
                        title: "No Tracking",
                        text: "SmartSpend does not track you across apps or websites, does not sell your data, and does not show third-party ads."
                    )

                    policySection(
                        title: "Support",
                        text: "If you email support, your message is used only to respond to your request."
                    )

                    policySection(
                        title: "Accounts and Sync",
                        text: "SmartSpend currently does not require an account and does not upload your data to a SmartSpend server."
                    )

                    policySection(
                        title: "Contact",
                        text: "tursunov.umidjon.uz@gmail.com"
                    )
                }
                .padding(24)
            }
            .navigationTitle("privacy_policy".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SmartSpend Privacy")
                .font(.title.bold())

            Text("Effective date: August 23, 2026")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func policySection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
