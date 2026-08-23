import SwiftUI

struct MainTabView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @ObservedObject private var tabManager = TabManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingAddExpense = false

    var body: some View {
        TabView(selection: $tabManager.selectedTab) {
            DashboardView()
                .tabItem {
                    Label("dashboard".localized, systemImage: "house.fill")
                }
                .tag(0)

            ExpenseListView()
                .tabItem {
                    Label("expenses".localized, systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            AnalyticsView()
                .tabItem {
                    Label("analytics".localized, systemImage: "chart.bar.fill")
                }
                .tag(2)

            RecurringExpensesView()
                .tabItem {
                    Label("recurring".localized, systemImage: "repeat")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("settings".localized, systemImage: "gear")
                }
                .tag(4)
        }
        .tint(Color(.systemBlue))
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView()
        }
        .onAppear {
            checkAddExpenseIntent()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkAddExpenseIntent()
            }
        }
    }

    private func checkAddExpenseIntent() {
        let defaults = UserDefaults(suiteName: "group.com.tursunov.SmartSpend") ?? UserDefaults.standard
        guard defaults.bool(forKey: "openAddExpense") else { return }
        defaults.removeObject(forKey: "openAddExpense")
        tabManager.switchToExpensesTab()
        DispatchQueue.main.async {
            showingAddExpense = true
        }
    }
}

struct SettingsView: View {
    @ObservedObject private var dataManager = DataManager.shared

    @State private var showingMonthlySalary = false
    @State private var showingCurrencySelection = false
    @State private var showingDeletedExpenses = false
    @State private var showingDataExport = false
    @State private var showingDataImport = false
    @State private var showingSupportChat = false
    @State private var showingPrivacyPolicy = false
    @State private var showingAlert = false
    
    private var currentMonthSalaryText: String {
        let currentSalary = dataManager.getCurrentMonthSalary()
        return currentSalary > 0 ? formatCurrency(currentSalary, dataManager.user.currency) : "not_set".localized
    }
    
    private var currentMonthSalaryColor: Color {
        let currentSalary = dataManager.getCurrentMonthSalary()
        return currentSalary > 0 ? .secondary : .orange
    }

    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0"
        return "SmartSpend v\(version) • Privacy First"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Section: Profile & Settings
                Section("profile".localized) {
                    Button(action: {
                        showingMonthlySalary = true
                    }) {
                        HStack {
                            Label("monthly_salaries".localized, systemImage: "calendar.badge.plus")
                                .foregroundStyle(Color(.systemBlue))
                            
                            Spacer()
                            
                            Text(currentMonthSalaryText)
                                .fontWeight(.medium)
                                .foregroundStyle(currentMonthSalaryColor)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        showingCurrencySelection = true
                    }) {
                        HStack {
                            Label("currency".localized, systemImage: "creditcard.fill")
                                .foregroundStyle(Color(.systemBlue))
                            
                            Spacer()
                            
                            Text(dataManager.user.currency.rawValue)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Section: App Features
                Section("features".localized) {
                    NavigationLink(destination: BudgetSettingsView()) {
                        Label("budget_goals".localized, systemImage: "target")
                            .foregroundStyle(Color(.systemGreen))
                    }
                    NavigationLink(destination: CategoryManagementView()) {
                        Label("categories".localized, systemImage: "tag.fill")
                            .foregroundStyle(Color(.systemOrange))
                    }
                    Button(action: { showingSupportChat = true }) {
                        HStack {
                            Label("Insights", systemImage: "chart.bar.doc.horizontal")
                                .foregroundStyle(Color(.systemIndigo))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Section: Support
                Section("support".localized) {
                    Button(action: {
                        showingPrivacyPolicy = true
                    }) {
                        Label("privacy_policy".localized, systemImage: "hand.raised.fill")
                            .foregroundStyle(Color(.systemBlue))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        if let url = URL(string: "mailto:tursunov.umidjon.uz@gmail.com") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("email_us".localized, systemImage: "envelope.fill")
                            .foregroundStyle(Color(.systemBlue))
                    }
                    .buttonStyle(.plain)
                }

                // Section: Data Control
                Section("data_management".localized) {
                    Button(action: {
                        showingDataImport = true
                    }) {
                        HStack {
                            Label("import_data".localized, systemImage: "square.and.arrow.down")
                                .foregroundStyle(Color(.systemBlue))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        showingDataExport = true
                    }) {
                        HStack {
                            Label("export_data".localized, systemImage: "square.and.arrow.up")
                                .foregroundStyle(Color(.systemGreen))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        showingDeletedExpenses = true
                    }) {
                        HStack {
                            Label("deleted_expenses".localized, systemImage: "trash.fill")
                                .foregroundStyle(Color(.systemBlue))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                // Danger Zone at the bottom
                Section {
                    Button(action: {
                        showingAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("clear_all_data".localized)
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                } footer: {
                    Text(appVersionText)
                        .frame(maxWidth: .infinity)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                }
            }
            .navigationTitle("settings".localized)
            .navigationBarTitleDisplayMode(.large)
            
            .sheet(isPresented: $showingSupportChat) {
                SupportChatView()
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }

            .sheet(isPresented: $showingMonthlySalary) {
                MonthlySalaryView()
                    .presentationDetents([.fraction(0.65), .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingCurrencySelection) {
                CurrencySelectionView()
            }
            .sheet(isPresented: $showingDeletedExpenses) {
                DeletedExpensesView()
            }
            .sheet(isPresented: $showingDataExport) {
                DataExportView()
            }
            .sheet(isPresented: $showingDataImport) {
                DataImportView()
            }
            .alert("clear_all_data".localized, isPresented: $showingAlert) {
                Button("cancel".localized, role: .cancel) { }
                Button("delete".localized, role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("clear_all_data_message".localized)
            }
        }
    }
    
    private func clearAllData() {
        dataManager.clearAllData()
    }

    private func formatCurrency(_ amount: Double, _ currency: Currency) -> String {
        return CurrencyFormatter.format(amount, currency: currency)
    }
}

#Preview {
    MainTabView()
}
