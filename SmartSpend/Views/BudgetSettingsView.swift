import SwiftUI

struct BudgetSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared
    @State private var showingAddGoal = false

    private var canSuggestBudgets: Bool {
        dataManager.expenses.count >= 10
    }

    var body: some View {
        NavigationStack {
            List {
                // Category budgets
                Section("budget_goals".localized) {
                    ForEach(dataManager.userCategories) { category in
                        CategoryBudgetSettingRow(category: category)
                    }
                }

                // Spending goals
                Section {
                    if dataManager.spendingGoals.isEmpty {
                        Text("No goals yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(dataManager.spendingGoals) { goal in
                            SpendingGoalRow(goal: goal, onDelete: {
                                dataManager.spendingGoals.removeAll { $0.id == goal.id }
                                dataManager.saveSpendingGoals()
                            })
                        }
                        .onDelete(perform: deleteGoal)
                    }
                } header: {
                    HStack {
                        Text("Spending Goals")
                        Spacer()
                        Button {
                            showingAddGoal = true
                        } label: {
                            Image(systemName: "plus")
                                .fontWeight(.medium)
                        }
                    }
                }

                // Actions
                Section {
                    Button(action: suggestBudgets) {
                        Label("Suggest Budgets from History", systemImage: "sparkles")
                    }
                    .disabled(!canSuggestBudgets)

                    Button(role: .destructive, action: resetAllBudgets) {
                        Label("Reset All Budgets", systemImage: "arrow.counterclockwise")
                    }
                } footer: {
                    if !canSuggestBudgets {
                        Text("Add at least 10 expenses to unlock budget suggestions.")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Budget Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dataManager.saveBudgets()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddSpendingGoalView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                dataManager.updateSpendingGoalProgress()
            }
        }
    }
    
    private func deleteGoal(at offsets: IndexSet) {
        dataManager.spendingGoals.remove(atOffsets: offsets)
        dataManager.saveSpendingGoals()
    }
    
    private func resetAllBudgets() {
        for i in 0..<dataManager.categoryBudgets.count {
            dataManager.categoryBudgets[i].amount = 0
            dataManager.categoryBudgets[i].isEnabled = false
        }
        dataManager.saveBudgets()
        
        // Force UI refresh by triggering objectWillChange
        dataManager.objectWillChange.send()
    }
    
    private func suggestBudgets() {
        let calendar = Calendar.current
        let now = Date()
        
        // Use last 2 months for trend detection
        guard let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now) else { return }
        
        let recentExpenses = dataManager.expenses.filter { $0.date >= twoMonthsAgo }
        
        // Group by month to calculate average
        let groupedByMonth = Dictionary(grouping: recentExpenses) { exp in
            calendar.dateComponents([.year, .month], from: exp.date)
        }
        
        let monthCount = max(1, Double(groupedByMonth.count))
        
        for category in dataManager.userCategories {
            let catExpenses = recentExpenses.filter { $0.categoryId == category.id }
            
            if !catExpenses.isEmpty {
                let total = catExpenses.reduce(0) { $0 + $1.amount }
                let monthlyAvg = total / monthCount
                
                // Logic: Suggest a budget that is 90% of your average for essential, 
                // or 110% for flexible (safety net). We'll go with 105% as a general realistic goal.
                let suggested = (monthlyAvg * 1.05).rounded()
                
                if let index = dataManager.categoryBudgets.firstIndex(where: { $0.categoryId == category.id }) {
                    dataManager.categoryBudgets[index].amount = suggested
                    dataManager.categoryBudgets[index].isEnabled = true
                } else {
                    let newBudget = CategoryBudget(categoryId: category.id, amount: suggested, isEnabled: true)
                    dataManager.categoryBudgets.append(newBudget)
                }
            }
        }
        
        dataManager.saveBudgets()
        dataManager.objectWillChange.send()
        
        // Optional: Trigger a haptic feedback or simple alert to inform the user
    }
}

struct CategoryBudgetSettingRow: View {
    let category: UserCategory
    @ObservedObject private var dataManager = DataManager.shared
    @State private var budgetAmount: String = ""
    @State private var isEnabled: Bool = false

    private var budget: CategoryBudget? {
        dataManager.categoryBudgets.first { $0.categoryId == category.id }
    }

    private var currentMonthSpent: Double {
        let calendar = Calendar.current
        return dataManager.expenses.filter {
            calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) &&
            $0.categoryId == category.id
        }.reduce(0) { $0 + $1.amount }
    }

    private var isOverBudget: Bool {
        guard let b = budget, b.isEnabled, b.amount > 0 else { return false }
        return currentMonthSpent > b.amount
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.iconSystemName)
                .foregroundStyle(category.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                if isEnabled && currentMonthSpent > 0 {
                    Text(CurrencyFormatter.format(currentMonthSpent, currency: dataManager.user.currency))
                        .font(.caption)
                        .foregroundStyle(isOverBudget ? .red : .secondary)
                }
            }

            Spacer()

            if isEnabled {
                TextField("0", text: $budgetAmount)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 110)
                    .onChange(of: budgetAmount) { _, _ in updateBudget() }
            }

            Toggle("", isOn: $isEnabled.animation())
                .labelsHidden()
        }
        .onAppear { updateLocalState() }
        .onChange(of: isEnabled) { _, _ in updateBudget() }
        .onChange(of: dataManager.categoryBudgets) { _, _ in updateLocalState() }
    }
    
    private func updateBudget() {
        let amount = Double(budgetAmount) ?? 0
        if let index = dataManager.categoryBudgets.firstIndex(where: { $0.categoryId == category.id }) {
            dataManager.categoryBudgets[index].amount = amount
            dataManager.categoryBudgets[index].isEnabled = isEnabled
        } else {
            let newBudget = CategoryBudget(categoryId: category.id, amount: amount, isEnabled: isEnabled)
            dataManager.categoryBudgets.append(newBudget)
        }
    }
    
    private func updateLocalState() {
        if let budget = budget {
            budgetAmount = budget.amount > 0 ? String(format: "%.0f", budget.amount) : ""
            isEnabled = budget.isEnabled
        } else {
            budgetAmount = ""
            isEnabled = false
        }
    }
}

struct SpendingGoalRow: View {
    let goal: SpendingGoal
    var onDelete: (() -> Void)? = nil
    @ObservedObject private var dataManager = DataManager.shared
    @State private var showingCompletionAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(goal.title)
                    .fontWeight(.medium)
                Spacer()
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                Text("\(Int(goal.progress * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(goal.isCompleted ? .green : .secondary)
            }

            ProgressView(value: goal.progress)
                .tint(goal.isCompleted ? Color.green : Color.accentColor)

            HStack {
                Text(CurrencyFormatter.format(goal.currentAmount, currency: dataManager.user.currency))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("of \(CurrencyFormatter.format(goal.targetAmount, currency: dataManager.user.currency)) · \(goal.deadline, style: .date)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .onChange(of: goal.progress) { _, newProgress in
            if newProgress >= 1.0 && !goal.isCompleted {
                showingCompletionAlert = true
            }
        }
        .alert("Goal Completed!", isPresented: $showingCompletionAlert) {
            Button("OK") { }
        } message: {
            Text("You've reached your goal: \(goal.title)")
        }
    }
}

struct AddSpendingGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared
    
    @State private var title = ""
    @State private var targetAmount = ""
    @State private var deadline = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
    @State private var selectedCategory: UserCategory?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Goal title", text: $title)
                        .textInputAutocapitalization(.words)
                    
                    HStack {
                        Text(dataManager.user.currency.symbol)
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $targetAmount)
                            .keyboardType(.decimalPad)
                    }
                    
                    DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                    
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select Category").tag(nil as UserCategory?)
                        ForEach(dataManager.userCategories) { category in
                            HStack {
                                Image(systemName: category.iconSystemName)
                                Text(category.name)
                            }
                            .tag(category as UserCategory?)
                        }
                    }
                } header: {
                    Text("Goal Details")
                } footer: {
                    Text("Set a savings goal with a target amount and deadline.")
                        .font(.caption)
                }
            }
            .navigationTitle("New Spending Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.tint)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(title.isEmpty || targetAmount.isEmpty || Double(targetAmount) == nil || selectedCategory == nil)
                    .foregroundStyle(.tint)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if selectedCategory == nil {
                    selectedCategory = dataManager.userCategories.first
                }
            }
        }
    }
    
    private func saveGoal() {
        guard let amount = Double(targetAmount), 
              amount > 0,
              let categoryId = selectedCategory?.id else { return }
        
        let goal = SpendingGoal(
            title: title, 
            targetAmount: amount, 
            deadline: deadline, 
            categoryId: categoryId
        )
        dataManager.spendingGoals.append(goal)
        dataManager.saveSpendingGoals()
        dismiss()
    }
}

#Preview {
    BudgetSettingsView()
}
