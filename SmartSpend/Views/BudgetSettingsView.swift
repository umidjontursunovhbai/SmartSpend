import SwiftUI

struct BudgetSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared

    private let focusCategoryID: UUID?

    @State private var showingAddGoal = false
    @State private var showingResetConfirmation = false

    init(focusCategoryID: UUID? = nil) {
        self.focusCategoryID = focusCategoryID
    }

    private var canSuggestBudgets: Bool {
        dataManager.expenses.count >= 10
    }

    private var activeBudgets: [CategoryBudget] {
        dataManager.categoryBudgets.filter { $0.isEnabled && $0.amount > 0 }
    }

    private var currentMonthSpendingByCategory: [UUID: Double] {
        BudgetPeriodCalculator.totalsByCategory(
            for: dataManager.expenses,
            in: BudgetPeriodCalculator.monthInterval(containing: Date())
        )
    }

    private var totalBudget: Double {
        activeBudgets.reduce(0) { $0 + $1.amount }
    }

    private func currentMonthSpent(using spendingByCategory: [UUID: Double]) -> Double {
        let activeCategoryIDs = Set(activeBudgets.map(\.categoryId))

        return spendingByCategory.reduce(into: 0) { total, entry in
            guard activeCategoryIDs.contains(entry.key) else { return }
            total += entry.value
        }
    }

    private func budgetProgress(currentMonthSpent: Double) -> Double {
        guard totalBudget > 0 else { return 0 }
        return min(currentMonthSpent / totalBudget, 1)
    }

    private func budgetProgressColor(currentMonthSpent: Double, progress: Double) -> Color {
        if totalBudget > 0, currentMonthSpent > totalBudget { return Color(.systemRed) }
        if progress >= 0.8 { return Color(.systemOrange) }
        return Color(.systemBlue)
    }

    var body: some View {
        let spendingByCategory = currentMonthSpendingByCategory
        let spentThisMonth = currentMonthSpent(using: spendingByCategory)

        return NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 28) {
                            monthlyOverview(currentMonthSpent: spentThisMonth)
                            categoryBudgetsSection(spendingByCategory: spendingByCategory)
                            spendingGoalsSection
                            budgetToolsSection
                        }
                        .padding(.horizontal, iOSDesignSystem.Spacing.screenMargin)
                        .padding(.top, 12)
                        .padding(.bottom, 36)
                    }
                    .scrollIndicators(.hidden)
                    .onAppear {
                        scrollToFocusedCategory(using: proxy)
                    }
                }
            }
            .navigationTitle("budget_goals".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done".localized) {
                        dataManager.saveBudgets()
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .frame(minWidth: iOSDesignSystem.Size.minimumTapTarget,
                           minHeight: iOSDesignSystem.Size.minimumTapTarget)
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddSpendingGoalView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color.white)
            }
            .alert("Reset all category budgets?", isPresented: $showingResetConfirmation) {
                Button("cancel".localized, role: .cancel) { }
                Button("reset".localized, role: .destructive, action: resetAllBudgets)
            } message: {
                Text("Your spending goals will stay in place.")
            }
            .onAppear {
                dataManager.updateSpendingGoalProgress()
            }
            .onDisappear {
                dataManager.saveBudgets()
            }
        }
        .preferredColorScheme(.light)
    }

    private func monthlyOverview(currentMonthSpent: Double) -> some View {
        let progress = budgetProgress(currentMonthSpent: currentMonthSpent)
        let progressColor = budgetProgressColor(currentMonthSpent: currentMonthSpent, progress: progress)

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("THIS MONTH")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)

                    Text(totalBudget > 0
                         ? CurrencyFormatter.format(totalBudget, currency: dataManager.user.currency)
                         : "No budget set")
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(progressColor,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(Int((progress * 100).rounded()))%")
                        .font(.caption.weight(.bold))
                        .fontDesign(.rounded)
                }
                .frame(width: 58, height: 58)
                .accessibilityLabel("Budget used")
                .accessibilityValue("\(Int((progress * 100).rounded())) percent")
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(progressColor)
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 8)

            HStack(spacing: 12) {
                overviewMetric(
                    label: "Spent",
                    value: CurrencyFormatter.format(currentMonthSpent, currency: dataManager.user.currency),
                    color: progressColor
                )

                Divider()
                    .frame(height: 34)

                overviewMetric(
                    label: currentMonthSpent > totalBudget && totalBudget > 0 ? "Over" : "Remaining",
                    value: CurrencyFormatter.format(abs(totalBudget - currentMonthSpent), currency: dataManager.user.currency),
                    color: currentMonthSpent > totalBudget && totalBudget > 0 ? Color(.systemRed) : Color(.systemGreen)
                )
            }
        }
        .padding(20)
        .liquidGlassCard(cornerRadius: 22)
    }

    private func overviewMetric(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func categoryBudgetsSection(spendingByCategory: [UUID: Double]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(
                title: "Category budgets",
                detail: activeBudgets.isEmpty ? nil : "\(activeBudgets.count) active"
            )

            if dataManager.userCategories.isEmpty {
                BudgetEmptyState(
                    icon: "tag",
                    title: "No categories yet",
                    message: "Create a category or import expenses before setting category budgets."
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(dataManager.userCategories) { category in
                        CategoryBudgetSettingRow(
                            category: category,
                            budget: dataManager.categoryBudgets.first { $0.categoryId == category.id },
                            currentMonthSpent: spendingByCategory[category.id, default: 0],
                            currency: dataManager.user.currency,
                            onChange: { amount, isEnabled in
                                updateBudget(for: category.id, amount: amount, isEnabled: isEnabled)
                            }
                        )
                            .id(category.id)
                            .overlay {
                                if focusCategoryID == category.id {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(category.color.opacity(0.8), lineWidth: 2)
                                }
                            }
                    }
                }
            }
        }
    }

    private func scrollToFocusedCategory(using proxy: ScrollViewProxy) {
        guard let focusCategoryID else { return }

        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(focusCategoryID, anchor: .center)
            }
        }
    }

    private func updateBudget(for categoryID: UUID, amount: Double, isEnabled: Bool) {
        if let index = dataManager.categoryBudgets.firstIndex(where: { $0.categoryId == categoryID }) {
            guard dataManager.categoryBudgets[index].amount != amount
                    || dataManager.categoryBudgets[index].isEnabled != isEnabled else { return }
            dataManager.categoryBudgets[index].amount = amount
            dataManager.categoryBudgets[index].isEnabled = isEnabled
        } else {
            dataManager.categoryBudgets.append(
                CategoryBudget(categoryId: categoryID, amount: amount, isEnabled: isEnabled)
            )
        }
    }

    private var spendingGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                sectionHeading(
                    title: "Spending goals",
                    detail: dataManager.spendingGoals.isEmpty ? nil : "\(dataManager.spendingGoals.count)"
                )

                Button {
                    showingAddGoal = true
                } label: {
                    HeroIcon("plus", size: 20)
                        .foregroundStyle(Color(.systemBlue))
                        .frame(width: iOSDesignSystem.Size.minimumTapTarget,
                               height: iOSDesignSystem.Size.minimumTapTarget)
                        .liquidGlassSurface(Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add spending goal")
            }

            if dataManager.spendingGoals.isEmpty {
                BudgetEmptyState(
                    icon: "flag",
                    title: "No spending goals",
                    message: "Create a target for a category and track progress over time.",
                    actionTitle: "Add goal",
                    action: { showingAddGoal = true }
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(dataManager.spendingGoals) { goal in
                        SpendingGoalRow(goal: goal) {
                            dataManager.spendingGoals.removeAll { $0.id == goal.id }
                            dataManager.saveSpendingGoals()
                        }
                    }
                }
            }
        }
    }

    private var budgetToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(title: "Budget tools")

            VStack(spacing: 0) {
                Button(action: suggestBudgets) {
                    budgetToolRow(
                        icon: "sparkles",
                        title: "Suggest from history",
                        detail: canSuggestBudgets
                            ? "Use recent spending to set realistic category limits."
                            : "Add at least 10 expenses to unlock suggestions.",
                        tint: Color(.systemIndigo)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canSuggestBudgets)
                .opacity(canSuggestBudgets ? 1 : 0.48)

                Divider()
                    .padding(.leading, 60)

                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    budgetToolRow(
                        icon: "arrow-path",
                        title: "Reset category budgets",
                        detail: "Turn off every category limit and clear its amount.",
                        tint: Color(.systemRed)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .liquidGlassCard(cornerRadius: 18)
        }
    }

    private func sectionHeading(title: String, detail: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.title3.weight(.bold))
            Spacer()
            if let detail {
                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
    }

    private func budgetToolRow(icon: String, title: String, detail: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            HeroIcon(icon, size: 21)
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint == Color(.systemRed) ? tint : Color.primary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            HeroIcon("chevron-right", size: 16)
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .frame(minHeight: 68)
        .contentShape(Rectangle())
    }

    private func resetAllBudgets() {
        for index in dataManager.categoryBudgets.indices {
            dataManager.categoryBudgets[index].amount = 0
            dataManager.categoryBudgets[index].isEnabled = false
        }
        dataManager.saveBudgets()
        dataManager.objectWillChange.send()
    }

    private func suggestBudgets() {
        let calendar = Calendar.current
        let now = Date()

        guard let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now) else { return }

        let recentExpenses = dataManager.expenses.filter { $0.date >= twoMonthsAgo }
        let groupedByMonth = Dictionary(grouping: recentExpenses) { expense in
            calendar.dateComponents([.year, .month], from: expense.date)
        }
        let monthCount = max(1, Double(groupedByMonth.count))

        for category in dataManager.userCategories {
            let categoryExpenses = recentExpenses.filter { $0.categoryId == category.id }
            guard !categoryExpenses.isEmpty else { continue }

            let total = categoryExpenses.reduce(0) { $0 + $1.amount }
            let suggested = ((total / monthCount) * 1.05).rounded()

            if let index = dataManager.categoryBudgets.firstIndex(where: { $0.categoryId == category.id }) {
                dataManager.categoryBudgets[index].amount = suggested
                dataManager.categoryBudgets[index].isEnabled = true
            } else {
                dataManager.categoryBudgets.append(
                    CategoryBudget(categoryId: category.id, amount: suggested, isEnabled: true)
                )
            }
        }

        dataManager.saveBudgets()
        dataManager.objectWillChange.send()
    }
}

struct CategoryBudgetSettingRow: View {
    let category: UserCategory
    let budget: CategoryBudget?
    let currentMonthSpent: Double
    let currency: Currency
    let onChange: (Double, Bool) -> Void

    @State private var budgetAmount = ""
    @State private var isEnabled = false

    init(
        category: UserCategory,
        budget: CategoryBudget?,
        currentMonthSpent: Double,
        currency: Currency,
        onChange: @escaping (Double, Bool) -> Void
    ) {
        self.category = category
        self.budget = budget
        self.currentMonthSpent = currentMonthSpent
        self.currency = currency
        self.onChange = onChange
        _budgetAmount = State(
            initialValue: budget.map { $0.amount > 0 ? AmountInputFormatter.formatValue($0.amount) : "" } ?? ""
        )
        _isEnabled = State(initialValue: budget?.isEnabled ?? false)
    }

    private var enteredAmount: Double {
        AmountInputFormatter.parse(budgetAmount) ?? 0
    }

    private var progress: Double {
        guard isEnabled, enteredAmount > 0 else { return 0 }
        return min(currentMonthSpent / enteredAmount, 1)
    }

    private var isOverBudget: Bool {
        isEnabled && enteredAmount > 0 && currentMonthSpent > enteredAmount
    }

    private var statusColor: Color {
        if isOverBudget { return Color(.systemRed) }
        if progress >= 0.8 { return Color(.systemOrange) }
        return category.color
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                HeroIcon(systemName: category.iconSystemName, size: 22)
                    .foregroundStyle(category.color)
                    .frame(width: 44, height: 44)
                    .background(category.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.name)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)

                    Text(isEnabled ? "Monthly limit on" : "No monthly limit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Toggle("", isOn: $isEnabled.animation(.easeInOut(duration: 0.18)))
                    .labelsHidden()
                    .tint(category.color)
                    .accessibilityLabel("Budget for \(category.name)")
            }

            if isEnabled {
                Divider()

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Monthly limit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("0", text: $budgetAmount)
                            .keyboardType(.decimalPad)
                            .font(.body.weight(.semibold))
                            .fontDesign(.rounded)
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)
                    }

                    Text(currency.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 54)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .tint(statusColor)

                    HStack {
                        Text("Spent \(CurrencyFormatter.format(currentMonthSpent, currency: currency))")
                        Spacer()
                        Text(isOverBudget ? "Over limit" : "\(Int((progress * 100).rounded()))% used")
                            .foregroundStyle(isOverBudget ? Color(.systemRed) : Color.secondary)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .budgetScrollCard(cornerRadius: 18)
        .onChange(of: isEnabled) { _, _ in
            updateBudget()
        }
        .onChange(of: budgetAmount) { _, _ in
            formatBudgetInput()
            updateBudget()
        }
        .onChange(of: budget) { _, newBudget in
            updateLocalState(from: newBudget)
        }
    }

    private func updateBudget() {
        let amount = AmountInputFormatter.parse(budgetAmount) ?? 0
        guard budget?.amount != amount || budget?.isEnabled != isEnabled else { return }
        onChange(amount, isEnabled)
    }

    private func updateLocalState(from budget: CategoryBudget?) {
        guard let budget else {
            if !budgetAmount.isEmpty { budgetAmount = "" }
            if isEnabled { isEnabled = false }
            return
        }

        let formattedAmount = budget.amount > 0 ? AmountInputFormatter.formatValue(budget.amount) : ""
        if budgetAmount != formattedAmount { budgetAmount = formattedAmount }
        if isEnabled != budget.isEnabled { isEnabled = budget.isEnabled }
    }

    private func formatBudgetInput() {
        let formatted = AmountInputFormatter.formatEditingText(budgetAmount)
        if formatted != budgetAmount {
            budgetAmount = formatted
        }
    }
}

struct SpendingGoalRow: View {
    let goal: SpendingGoal
    var onDelete: (() -> Void)?

    @ObservedObject private var dataManager = DataManager.shared
    @State private var showingCompletionAlert = false

    private var category: UserCategory {
        dataManager.resolveCategory(id: goal.categoryId)
    }

    private var deadlineText: String {
        goal.deadline.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                HeroIcon(systemName: category.iconSystemName, size: 21)
                    .foregroundStyle(category.color)
                    .frame(width: 42, height: 42)
                    .background(category.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.title)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                    Text(category.name)
                        .font(.caption)
                        .foregroundStyle(category.color)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if let onDelete {
                    Button(role: .destructive, action: onDelete) {
                        HeroIcon("trash", size: 19)
                            .foregroundStyle(Color(.systemRed))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete \(goal.title)")
                }
            }

            VStack(spacing: 8) {
                ProgressView(value: goal.progress)
                    .tint(goal.isCompleted ? Color(.systemGreen) : category.color)

                HStack(alignment: .firstTextBaseline) {
                    Text(CurrencyFormatter.format(goal.currentAmount, currency: dataManager.user.currency))
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(.rounded)
                    Text("of \(CurrencyFormatter.format(goal.targetAmount, currency: dataManager.user.currency))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int((goal.progress * 100).rounded()))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(goal.isCompleted ? Color(.systemGreen) : category.color)
                }
            }

            HStack(spacing: 6) {
                HeroIcon("calendar", size: 14)
                Text("Due \(deadlineText)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .budgetScrollCard(cornerRadius: 18)
        .onChange(of: goal.progress) { _, newProgress in
            if newProgress >= 1, !goal.isCompleted {
                showingCompletionAlert = true
            }
        }
        .alert("Goal completed", isPresented: $showingCompletionAlert) {
            Button("ok".localized) { }
        } message: {
            Text("You reached your goal: \(goal.title)")
        }
    }
}

private extension View {
    func budgetScrollCard(cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return self
            .background(Color(.secondarySystemBackground), in: shape)
            .overlay(shape.stroke(Color.black.opacity(0.055), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.035), radius: 5, x: 0, y: 2)
    }
}

struct AddSpendingGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared

    @State private var title = ""
    @State private var targetAmount = ""
    @State private var deadline = Date().addingTimeInterval(30 * 24 * 60 * 60)
    @State private var selectedCategory: UserCategory?

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let amount = AmountInputFormatter.parse(targetAmount),
              amount > 0,
              selectedCategory != nil else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        goalIntro
                        goalDetails

                        Button(action: saveGoal) {
                            HStack(spacing: 8) {
                                HeroIcon("plus", size: 18)
                                Text("Add goal")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color(.systemBlue), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .opacity(canSave ? 1 : 0.4)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSave)
                    }
                    .padding(.horizontal, iOSDesignSystem.Spacing.screenMargin)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("New spending goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                    .frame(minHeight: iOSDesignSystem.Size.minimumTapTarget)
                }
            }
            .onAppear {
                if selectedCategory == nil {
                    selectedCategory = dataManager.userCategories.first
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private var goalIntro: some View {
        HStack(spacing: 14) {
            HeroIcon("flag", size: 25)
                .foregroundStyle(Color(.systemBlue))
                .frame(width: 52, height: 52)
                .liquidGlassSurface(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Set a clear target")
                    .font(.headline)
                Text("Choose a category, amount, and deadline. Progress updates from your expenses.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .liquidGlassCard(cornerRadius: 18)
    }

    private var goalDetails: some View {
        VStack(spacing: 0) {
            goalField(label: "Goal name") {
                TextField("e.g. Dining limit", text: $title)
                    .textInputAutocapitalization(.words)
                    .multilineTextAlignment(.trailing)
            }

            Divider().padding(.leading, 16)

            goalField(label: "Target amount") {
                HStack(spacing: 8) {
                    TextField("0", text: $targetAmount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .fontDesign(.rounded)
                        .onChange(of: targetAmount) { _, _ in formatTargetAmountInput() }
                    Text(dataManager.user.currency.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: 180)
            }

            Divider().padding(.leading, 16)

            goalField(label: "Deadline") {
                DatePicker("", selection: $deadline, in: Date()..., displayedComponents: .date)
                    .labelsHidden()
            }

            Divider().padding(.leading, 16)

            goalField(label: "Category") {
                if dataManager.userCategories.isEmpty {
                    Text("No categories")
                        .foregroundStyle(.secondary)
                } else {
                    Menu {
                        ForEach(dataManager.userCategories) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category.name)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if let selectedCategory {
                                HeroIcon(systemName: selectedCategory.iconSystemName, size: 17)
                                    .foregroundStyle(selectedCategory.color)
                                Text(selectedCategory.name)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                            } else {
                                Text("Select category")
                                    .foregroundStyle(.secondary)
                            }
                            HeroIcon("chevron-right", size: 14)
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                        .frame(minHeight: iOSDesignSystem.Size.minimumTapTarget)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .liquidGlassCard(cornerRadius: 18)
    }

    private func goalField<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 16) {
            Text(label)
                .font(.subheadline.weight(.medium))
            Spacer(minLength: 12)
            content()
        }
        .frame(minHeight: 58)
        .contentShape(Rectangle())
    }

    private func saveGoal() {
        guard canSave,
              let amount = AmountInputFormatter.parse(targetAmount),
              let categoryId = selectedCategory?.id else { return }

        let goal = SpendingGoal(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            targetAmount: amount,
            deadline: deadline,
            categoryId: categoryId
        )
        dataManager.spendingGoals.append(goal)
        dataManager.saveSpendingGoals()
        dismiss()
    }

    private func formatTargetAmountInput() {
        let formatted = AmountInputFormatter.formatEditingText(targetAmount)
        if formatted != targetAmount {
            targetAmount = formatted
        }
    }
}

private struct BudgetEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            HeroIcon(icon, size: 26)
                .foregroundStyle(Color(.systemBlue))
                .frame(width: 52, height: 52)
                .background(Color(.systemBlue).opacity(0.09), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.systemBlue))
                    .padding(.horizontal, 18)
                    .frame(minHeight: iOSDesignSystem.Size.minimumTapTarget)
                    .liquidGlassSurface(Capsule())
                    .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 26)
        .liquidGlassCard(cornerRadius: 18)
    }
}

#Preview {
    BudgetSettingsView()
}
