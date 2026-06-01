import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @ObservedObject private var tabManager = TabManager.shared
    @State private var showingAddExpense = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    remainingBudgetCard
                    quickStatsCard
                    if !upcomingBills.isEmpty { upcomingBillsCard }
                    if !budgetAlerts.isEmpty { budgetAlertsCard }
                    recentExpensesCard
                    if !dataManager.spendingGoals.isEmpty {
                        SpendingGoalsView(goals: dataManager.spendingGoals)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("smartspend".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddExpense = true }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.tint)
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
        }
    }

    private var currency: Currency { dataManager.user.currency }

    // MARK: - Derived data

    private var monthExpenses: [Expense] {
        dataManager.expenses.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }
    private var monthTotal: Double { monthExpenses.reduce(0) { $0 + $1.amount } }
    private var monthlySalary: Double { dataManager.getCurrentMonthSalary() }
    private var remaining: Double { monthlySalary - monthTotal }
    private var budgetProgress: Double { monthlySalary > 0 ? min(monthTotal / monthlySalary, 1) : 0 }

    private var daysRemainingInMonth: Int {
        let total = calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
        let day = calendar.component(.day, from: Date())
        return max(total - day + 1, 1)
    }
    private var dailyAllowance: Double { max(remaining, 0) / Double(daysRemainingInMonth) }

    private var todayTotal: Double { dataManager.getTodaysExpensesTotal() }
    private var todayCount: Int { dataManager.getTodaysExpenses().count }

    private var weekTotal: Double {
        guard let start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        return dataManager.expenses.filter { $0.date >= start }.reduce(0) { $0 + $1.amount }
    }

    private var recentExpenses: [Expense] {
        Array(dataManager.expenses.sorted { $0.date > $1.date }.prefix(5))
    }

    private var upcomingBills: [RecurringExpense] {
        let now = calendar.startOfDay(for: Date())
        let limit = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        return dataManager.recurringExpenses
            .filter { $0.isActive && $0.nextDueDate >= now && $0.nextDueDate <= limit }
            .sorted { $0.nextDueDate < $1.nextDueDate }
    }

    private var budgetAlerts: [(category: UserCategory, spent: Double, limit: Double)] {
        dataManager.categoryBudgets
            .filter { $0.isEnabled && $0.amount > 0 }
            .compactMap { budget -> (category: UserCategory, spent: Double, limit: Double)? in
                let spent = monthExpenses
                    .filter { $0.categoryId == budget.categoryId }
                    .reduce(0) { $0 + $1.amount }
                guard spent > budget.amount * 0.8 else { return nil }
                return (dataManager.resolveCategory(id: budget.categoryId), spent, budget.amount)
            }
            .sorted { ($0.spent / $0.limit) > ($1.spent / $1.limit) }
    }

    // MARK: - Cards

    private var remainingBudgetCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("remaining_this_month".localized.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            if monthlySalary > 0 {
                Text(CurrencyFormatter.format(remaining, currency: currency))
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(remaining < 0 ? .red : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                ProgressView(value: budgetProgress)
                    .tint(budgetProgress > 0.8 ? Color.red : Color.accentColor)

                if remaining > 0 {
                    Label(
                        String(format: "spend_per_day_format".localized,
                               CurrencyFormatter.format(dailyAllowance, currency: currency)),
                        systemImage: "calendar.day.timeline.left"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            } else {
                Text("income_not_set".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("set_income".localized) { tabManager.selectedTab = 4 }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .dashboardCard()
    }

    private var quickStatsCard: some View {
        HStack(spacing: 0) {
            statColumn(
                label: "today".localized,
                value: CurrencyFormatter.format(todayTotal, currency: currency),
                sub: todayCount == 1 ? "one_transaction".localized
                                     : String(format: "transactions_count_format".localized, todayCount)
            )
            Divider().frame(height: 42)
            statColumn(label: "this_week".localized,
                       value: CurrencyFormatter.format(weekTotal, currency: currency), sub: nil)
            Divider().frame(height: 42)
            statColumn(label: "time_period_this_month".localized,
                       value: CurrencyFormatter.format(monthTotal, currency: currency), sub: nil)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func statColumn(label: String, value: String, sub: String?) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.headline)
                .fontDesign(.rounded)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let sub {
                Text(sub).font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
    }

    private var upcomingBillsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader("upcoming_bills".localized)
            VStack(spacing: 0) {
                ForEach(Array(upcomingBills.enumerated()), id: \.element.id) { index, bill in
                    let cat = dataManager.resolveCategory(id: bill.categoryId)
                    HStack(spacing: 12) {
                        Image(systemName: cat.iconSystemName).foregroundStyle(cat.color).frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bill.title).lineLimit(1)
                            Text(dueText(bill.nextDueDate))
                                .font(.caption)
                                .foregroundStyle(dueColor(bill.nextDueDate))
                        }
                        Spacer()
                        Text(CurrencyFormatter.format(bill.amount, currency: currency)).fontWeight(.medium)
                    }
                    .padding(.vertical, 8)
                    if index < upcomingBills.count - 1 { Divider() }
                }
            }
        }
        .dashboardCard()
    }

    private var budgetAlertsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader("budget_alerts".localized)
            VStack(spacing: 0) {
                ForEach(Array(budgetAlerts.enumerated()), id: \.offset) { index, alert in
                    let over = alert.spent > alert.limit
                    HStack(spacing: 12) {
                        Image(systemName: alert.category.iconSystemName)
                            .foregroundStyle(alert.category.color).frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(alert.category.name)
                            Text("\(CurrencyFormatter.format(alert.spent, currency: currency)) / \(CurrencyFormatter.format(alert.limit, currency: currency))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(over ? "over_budget".localized : "near_limit".localized)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(over ? .red : .orange)
                    }
                    .padding(.vertical, 8)
                    if index < budgetAlerts.count - 1 { Divider() }
                }
            }
        }
        .dashboardCard()
    }

    private var recentExpensesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader("recent_expenses".localized,
                       actionTitle: recentExpenses.isEmpty ? nil : "view_all".localized) {
                tabManager.switchToExpensesTab()
            }
            if recentExpenses.isEmpty {
                Text("no_expenses_yet".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentExpenses.enumerated()), id: \.element.id) { index, expense in
                        let cat = dataManager.resolveCategory(id: expense.categoryId)
                        HStack(spacing: 12) {
                            Image(systemName: cat.iconSystemName).foregroundStyle(cat.color).frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(expense.title.isEmpty ? cat.name : expense.title).lineLimit(1)
                                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(CurrencyFormatter.format(expense.amount, currency: currency)).fontWeight(.medium)
                        }
                        .padding(.vertical, 8)
                        if index < recentExpenses.count - 1 { Divider() }
                    }
                }
            }
        }
        .dashboardCard()
    }

    // MARK: - Helpers

    private func cardHeader(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action).font(.subheadline)
            }
        }
    }

    private func dueText(_ date: Date) -> String {
        if calendar.isDateInToday(date) { return "due_today".localized }
        if calendar.isDateInTomorrow(date) { return "due_tomorrow".localized }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()),
                                           to: calendar.startOfDay(for: date)).day ?? 0
        return String(format: "due_in_days_format".localized, days)
    }

    private func dueColor(_ date: Date) -> Color {
        (calendar.isDateInToday(date) || calendar.isDateInTomorrow(date)) ? .orange : .secondary
    }
}

private extension View {
    func dashboardCard() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
    }
}

struct BudgetDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared
    @State private var showingCustomMonthPicker = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Period Selector
                    timePeriodSelector
                    
                    // Budget Overview Card
                    budgetOverviewCard
                    
                    // Category Breakdown
                    categoryBreakdownCard
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("budget_details".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done".localized) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingCustomMonthPicker) {
                CustomMonthPickerView()
                    .presentationDetents([.fraction(0.85)])
            }
        }
    }
    
    private var timePeriodSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("time_period".localized)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            // Show custom date range if custom month is selected
            if dataManager.selectedTimePeriod == .customMonth {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("custom_date_range".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Text("\(formatDate(dataManager.customStartDate)) - \(formatDate(dataManager.customEndDate))")
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingCustomMonthPicker = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.tint)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Button(action: {
                        if period == .customMonth {
                            showingCustomMonthPicker = true
                        } else {
                            dataManager.selectedTimePeriod = period
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: period.icon)
                                .font(.title3)
                                .foregroundStyle(dataManager.selectedTimePeriod == period ? .white : .primary)
                            
                            Text(period.localizedName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(dataManager.selectedTimePeriod == period ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            dataManager.selectedTimePeriod == period ? 
                            Color(.systemBlue) : 
                            Color(.systemGray6),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    dataManager.selectedTimePeriod == period ? Color.clear : Color(.systemGray4),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.2), value: dataManager.selectedTimePeriod)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var budgetOverviewCard: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Label("budget_overview".localized, systemImage: "chart.pie.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            // Progress Section
            VStack(spacing: 12) {
                HStack {
                    Text("budget_used".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(dataManager.getProgressPercentageForPeriod() * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(dataManager.getProgressPercentageForPeriod() > 0.8 ? .red : .primary)
                }
                
                ProgressView(value: dataManager.getProgressPercentageForPeriod())
                    .progressViewStyle(LinearProgressViewStyle(tint: dataManager.getProgressPercentageForPeriod() > 0.8 ? Color(.systemRed) : Color(.systemBlue)))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            // Budget Stats
            HStack(spacing: 16) {
                BudgetStatView(
                    title: "spent".localized,
                    amount: dataManager.getTotalExpensesForPeriod(),
                    currency: dataManager.user.currency,
                    color: Color(.systemRed)
                )
                
                Divider()
                    .frame(height: 40)
                
                BudgetStatView(
                    title: "remaining".localized,
                    amount: dataManager.getRemainingBudgetForPeriod(),
                    currency: dataManager.user.currency,
                    color: Color(.systemGreen)
                )
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var categoryBreakdownCard: some View {
        VStack(spacing: 16) {
            HStack {
                Label("category_breakdown".localized, systemImage: "chart.bar.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(dataManager.getCategoryBreakdownForPeriod().prefix(5), id: \.name) { item in
                    CategoryBreakdownRow(
                        name: item.name,
                        amount: item.amount,
                        total: dataManager.getTotalExpensesForPeriod(),
                        currency: dataManager.user.currency,
                        color: item.color,
                        icon: item.icon
                    )
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date)
    }
    
}

struct SpendingTrendsView: View {
    @ObservedObject private var dataManager = DataManager.shared
    
    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("spending_trends".localized)
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 16) {
                TrendStat(
                    title: "daily_avg".localized,
                    value: dataManager.getDailyAverageForPeriod(),
                    currency: dataManager.user.currency
                )
                Divider().frame(height: 40)
                TrendStat(
                    title: "weekly_avg".localized,
                    value: dataManager.getWeeklyAverageForPeriod(),
                    currency: dataManager.user.currency
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct TrendStat: View {
    let title: String
    let value: Double
    let currency: Currency

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(CurrencyFormatter.format(value, currency: currency))
                .font(.title3.weight(.semibold))
                .fontDesign(.rounded)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CategoryBreakdownRow: View {
    let name: String
    let amount: Double
    let total: Double
    let currency: Currency
    let color: Color
    let icon: String
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return amount / total
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("\(Int(percentage * 100))% \("of_total".localized)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(CurrencyFormatter.format(amount, currency: currency))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 8)
    }
}

struct SalaryHeaderView: View {
    let salary: Double
    let currency: Currency
    let onEditSalary: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("monthly_salary".localized, systemImage: "dollarsign.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: onEditSalary) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.borderless)
            }
            
            Text(formatCurrency(salary, currency))
                .font(.largeTitle)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func formatCurrency(_ amount: Double, _ currency: Currency) -> String {
        return CurrencyFormatter.format(amount, currency: currency)
    }
}

struct BudgetOverviewView: View {
    let totalExpenses: Double
    let remainingBudget: Double
    let salary: Double
    let currency: Currency
    
    var progressPercentage: Double {
        guard salary > 0 else { return 0 }
        return min(totalExpenses / salary, 1.0)
    }
    
    private var ringColor: Color {
        progressPercentage > 0.8 ? .red : .accentColor
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("budget_overview".localized)
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 24) {
                // Budget ring
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 9)
                    Circle()
                        .trim(from: 0, to: progressPercentage)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: progressPercentage)
                    VStack(spacing: 1) {
                        Text("\(Int(progressPercentage * 100))%")
                            .font(.title3.weight(.bold))
                            .fontDesign(.rounded)
                        Text("budget_used".localized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 96, height: 96)

                // Spent / remaining
                VStack(spacing: 10) {
                    statRow(title: "spent".localized, amount: totalExpenses, color: Color(.systemRed))
                    Divider()
                    statRow(title: "remaining".localized, amount: remainingBudget, color: Color(.systemGreen))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func statRow(title: String, amount: Double, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(CurrencyFormatter.format(amount, currency: currency))
                .font(.subheadline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

struct BudgetStatView: View {
    let title: String
    let amount: Double
    let currency: Currency
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Text(formatCurrency(amount, currency))
                .font(.title3)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatCurrency(_ amount: Double, _ currency: Currency) -> String {
        return CurrencyFormatter.format(amount, currency: currency)
    }
}

struct CategoryBreakdownView: View {
    let breakdown: [(name: String, amount: Double, color: Color, icon: String)]
    @ObservedObject private var dataManager = DataManager.shared

    private var total: Double { breakdown.reduce(0) { $0 + $1.amount } }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("category_breakdown".localized)
                    .font(.headline)
                Spacer()
            }

            if breakdown.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("no_expenses_yet".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                HStack(spacing: 20) {
                    Chart {
                        ForEach(breakdown.prefix(8), id: \.name) { item in
                            SectorMark(
                                angle: .value("Amount", item.amount),
                                innerRadius: .ratio(0.62),
                                angularInset: 1.5
                            )
                            .cornerRadius(4)
                            .foregroundStyle(item.color)
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(width: 120, height: 120)
                    .overlay {
                        VStack(spacing: 1) {
                            Text(CurrencyFormatter.formatCompact(total, currency: dataManager.user.currency))
                                .font(.subheadline.bold())
                                .fontDesign(.rounded)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text("spent".localized)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                    }

                    VStack(spacing: 10) {
                        ForEach(breakdown.prefix(4), id: \.name) { item in
                            HStack(spacing: 8) {
                                Circle().fill(item.color).frame(width: 8, height: 8)
                                Text(item.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Spacer()
                                Text(CurrencyFormatter.format(item.amount, currency: dataManager.user.currency))
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct CustomMonthPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared
    @State private var currentMonth: Date = Date()
    @State private var selectionStep: SelectionStep = .firstDate
    @State private var tempStartDate: Date = Date()
    @State private var tempEndDate: Date = Date()
    
    enum SelectionStep {
        case firstDate
        case secondDate
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with Instructions
                VStack(spacing: 20) {
                    // Instructions
                    Text(instructionText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    // From and To Buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            selectionStep = .firstDate
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 14, weight: .medium))
                                Text("from".localized)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(selectionStep == .firstDate ? .white : .blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectionStep == .firstDate ? Color.blue : Color.blue.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            selectionStep = .secondDate
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 14, weight: .medium))
                                Text("to".localized)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(selectionStep == .secondDate ? .white : .blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectionStep == .secondDate ? Color.blue : Color.blue.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
                .background(Color(.systemGroupedBackground))
                
                // Calendar View
                VStack(spacing: 20) {
                    // Month Navigation
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(.systemBlue))
                                .frame(width: 36, height: 36)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text(monthYearString(from: currentMonth))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(.label))
                        
                        Spacer()
                        
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(.systemBlue))
                                .frame(width: 36, height: 36)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Calendar Grid
                    VStack(spacing: 12) {
                        // Day headers
                        HStack(spacing: 0) {
                            ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { index, day in
                                Text(day)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(.secondaryLabel))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Calendar days
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                            ForEach(Array(calendarDays.enumerated()), id: \.offset) { index, date in
                                if let date = date {
                                    CalendarDayView(
                                        date: date,
                                        state: dayState(for: date),
                                        isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month),
                                        action: { selectDate(date) }
                                    )
                                } else {
                                    Color.clear
                                        .frame(height: 40)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
            }
            .navigationTitle("select_custom_date_range".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done".localized) {
                        // Apply the selected date range when Done is pressed
                        dataManager.updateCustomDateRange(startDate: tempStartDate, endDate: tempEndDate)
                        dataManager.selectedTimePeriod = .customMonth
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                currentMonth = dataManager.customStartDate
                tempStartDate = dataManager.customStartDate
                tempEndDate = dataManager.customEndDate
            }
        }
    }
    
    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        
        var days: [Date?] = []
        let endDate = calendar.date(byAdding: .day, value: 41, to: startOfWeek) ?? startOfWeek
        
        var currentDate = startOfWeek
        while currentDate < endDate {
            if calendar.isDate(currentDate, equalTo: currentMonth, toGranularity: .month) {
                days.append(currentDate)
            } else {
                days.append(nil)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private func previousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    private func selectDate(_ date: Date) {
        switch selectionStep {
        case .firstDate:
            tempStartDate = date
            if tempEndDate < tempStartDate {
                tempEndDate = date
            }
        case .secondDate:
            tempEndDate = max(date, tempStartDate)
        }
    }
    
    private func dayState(for date: Date) -> CalendarDayView.DayState {
        let calendar = Calendar.current
        let isStart = calendar.isDate(date, inSameDayAs: tempStartDate)
        let isEnd = calendar.isDate(date, inSameDayAs: tempEndDate)
        
        if isStart && isEnd {
            return .single
        } else if isStart {
            return .start
        } else if isEnd {
            return .end
        } else if date > tempStartDate && date < tempEndDate {
            return .inRange
        } else {
            return .none
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private var instructionText: String {
        switch selectionStep {
        case .firstDate:
            return "tap_from_select_start".localized
        case .secondDate:
            return "select_end_date".localized
        }
    }
}



#Preview {
    DashboardView()
}
