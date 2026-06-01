import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @State private var selectedTimeframe: TimeFrame = .month
    @State private var showingBudgetSettings = false
    
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        
        var localizedName: String {
            switch self {
            case .week:
                return "timeframe_week".localized
            case .month:
                return "timeframe_month".localized
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    timeFramePicker
                    spendingHighlights
                    spendingTrendSection
                    categoryBreakdownSection
                    categoryBudgetSection
                    peakSpendingDaysSection
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("analytics_title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("budgets".localized) {
                        showingBudgetSettings = true
                    }
                    .foregroundStyle(.tint)
                    .fontWeight(.medium)
                }
            }
            .sheet(isPresented: $showingBudgetSettings) {
                BudgetSettingsView()
            }
            .onAppear {
                dataManager.updateSpendingGoalProgress()
            }
        }
    }
    
    private var timeFramePicker: some View {
        Picker("Time Frame", selection: $selectedTimeframe) {
            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                Text(timeFrame.localizedName).tag(timeFrame)
            }
        }
        .pickerStyle(.segmented)
    }

    private var spendingHighlights: some View {
        VStack(spacing: 0) {
            // Primary metric
            VStack(alignment: .leading, spacing: 6) {
                Text("spent".localized.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.format(currentPeriodTotal, currency: dataManager.user.currency))
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if previousPeriodTotal > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: spendingChangePercentage >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(trendSummary)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(spendingChangePercentage >= 0 ? .red : .green)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)

            Divider().padding(.leading, 16)

            // Secondary stats
            HStack(spacing: 0) {
                statColumn(title: "daily_avg".localized,
                           value: CurrencyFormatter.format(averageDailySpend, currency: dataManager.user.currency))
                Divider().frame(height: 36)
                statColumn(title: "Transactions", value: "\(expensesCount)")
                Divider().frame(height: 36)
                statColumn(title: "categories".localized, value: "\(categoriesUsedCount)")
            }
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func statColumn(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.headline)
                .fontDesign(.rounded)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
    }

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("category_breakdown".localized)

            if currentPeriodExpenses.isEmpty {
                emptyState
            } else {
                let data = groupExpensesByCategory(currentPeriodExpenses)
                HStack(spacing: 20) {
                    Chart {
                        ForEach(Array(data.keys), id: \.id) { category in
                            SectorMark(
                                angle: .value("Amount", data[category] ?? 0),
                                innerRadius: .ratio(0.62),
                                angularInset: 1.5
                            )
                            .cornerRadius(4)
                            .foregroundStyle(category.color)
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(width: 130, height: 130)
                    .overlay {
                        VStack(spacing: 0) {
                            Text("\(categoriesUsedCount)")
                                .font(.title2.bold())
                                .fontDesign(.rounded)
                            Text("categories".localized)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(data.keys.sorted { (data[$0] ?? 0) > (data[$1] ?? 0) }.prefix(4)), id: \.id) { category in
                            HStack(spacing: 8) {
                                Circle().fill(category.color).frame(width: 8, height: 8)
                                Text(category.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                Text(CurrencyFormatter.format(data[category] ?? 0, currency: dataManager.user.currency))
                                    .font(.caption.weight(.semibold))
                            }
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private var categoryBudgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader("budget_progress".localized)
                Spacer()
                Button("manage".localized) {
                    showingBudgetSettings = true
                }
                .font(.subheadline)
                .foregroundStyle(.tint)
            }

            let activeBudgets = dataManager.categoryBudgets.filter { $0.isEnabled }
            if activeBudgets.isEmpty {
                Text("no_budget_set".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 16) {
                    ForEach(activeBudgets) { budget in
                        CategoryBudgetRow(budget: budget)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var spendingTrendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    sectionHeader("spending_trends".localized)
                    Text(trendSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if previousPeriodTotal > 0 {
                    Text(trendSummary)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(spendingChangePercentage >= 0 ? Color.red.opacity(0.12) : Color.green.opacity(0.12))
                        )
                        .foregroundStyle(spendingChangePercentage >= 0 ? Color.red : Color.green)
                }
            }

            if dailySpendingPoints.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(dailySpendingPoints) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(Color.accentColor.opacity(0.18).gradient)
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(Color.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: selectedTimeframe == .week ? 7 : 5))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 200)
            }
        }
        .cardStyle()
    }

    private var peakSpendingDaysSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("peak_days".localized)

            if peakSpendingDays.isEmpty {
                emptyState
            } else {
                ForEach(Array(peakSpendingDays.prefix(3).enumerated()), id: \.offset) { index, day in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(dayLabel(for: day.date))
                                .font(.subheadline)
                            Text(day.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(CurrencyFormatter.format(day.amount, currency: dataManager.user.currency))
                                .font(.subheadline.weight(.medium))
                            Text(peakPercentage(for: day.amount))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if index < min(2, peakSpendingDays.count - 1) {
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Shared building blocks

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
    }

    private var emptyState: some View {
        Text("no_expenses_found".localized)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
    }
    
    
    // MARK: - Helper Methods
    
    private func expensesForCurrentPeriod() -> [Expense] {
        expenses(for: selectedTimeframe, offset: 0)
    }
    
    private func expensesForPreviousPeriod() -> [Expense] {
        expenses(for: selectedTimeframe, offset: 1)
    }
    
    private func expenses(for timeframe: TimeFrame, offset: Int) -> [Expense] {
        guard let interval = periodRange(for: timeframe, offset: offset) else { return [] }
        return dataManager.expenses.filter { interval.contains($0.date) }
    }
    
    private func periodRange(for timeframe: TimeFrame, offset: Int) -> DateInterval? {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeframe {
        case .week:
            guard let referenceDate = calendar.date(byAdding: .weekOfYear, value: -offset, to: now),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return nil }
            return interval
        case .month:
            guard let referenceDate = calendar.date(byAdding: .month, value: -offset, to: now),
                  let interval = calendar.dateInterval(of: .month, for: referenceDate) else { return nil }
            return interval
        }
    }
    
    private var currentPeriodExpenses: [Expense] {
        expensesForCurrentPeriod()
    }
    
    private var previousPeriodExpenses: [Expense] {
        expensesForPreviousPeriod()
    }
    
    private var currentPeriodTotal: Double {
        currentPeriodExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var previousPeriodTotal: Double {
        previousPeriodExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var spendingChangePercentage: Double {
        guard previousPeriodTotal > 0 else { return currentPeriodTotal > 0 ? 100 : 0 }
        return ((currentPeriodTotal - previousPeriodTotal) / previousPeriodTotal) * 100
    }
    
    private var spendingChangeDescription: String? {
        guard previousPeriodTotal > 0 else { return nil }
        let direction = spendingChangePercentage >= 0 ? "increase".localized : "decrease".localized
        return "\(String(format: "%.1f", abs(spendingChangePercentage)))% \(direction)"
    }
    
    private var trendSubtitle: String {
        "\(periodLabel(for: 0)) • \(periodLabel(for: 1))"
    }
    
    private var trendSummary: String {
        guard previousPeriodTotal > 0 else { return "no_change".localized }
        let direction = spendingChangePercentage >= 0 ? "increase".localized : "decrease".localized
        return "\(direction) \(String(format: "%.1f%%", abs(spendingChangePercentage)))"
    }
    
    private var averageDailySpend: Double {
        guard let interval = periodRange(for: selectedTimeframe, offset: 0) else { return 0 }
        let days = max(interval.duration / 86_400, 1)
        return currentPeriodTotal / days
    }
    
    private var categoriesUsedCount: Int {
        Set(currentPeriodExpenses.map { $0.categoryId }).count
    }
    
    private var expensesCount: Int {
        currentPeriodExpenses.count
    }
    
    private func periodLabel(for offset: Int) -> String {
        guard let interval = periodRange(for: selectedTimeframe, offset: offset) else { return "-" }
        let formatter = DateFormatter()
        switch selectedTimeframe {
        case .week:
            formatter.dateFormat = "MMM d"
            let end = Calendar.current.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
            return "\(formatter.string(from: interval.start)) - \(formatter.string(from: end))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: interval.start)
        }
    }
    
    private var dailySpendingPoints: [DailySpendingPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: currentPeriodExpenses) { calendar.startOfDay(for: $0.date) }
        return grouped.map { date, expenses in
            DailySpendingPoint(date: date, amount: expenses.reduce(0) { $0 + $1.amount })
        }
        .sorted { $0.date < $1.date }
    }
    
    private var peakSpendingDays: [PeakSpendingDay] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: currentPeriodExpenses) { calendar.startOfDay(for: $0.date) }
        return grouped.map { date, expenses in
            PeakSpendingDay(date: date, amount: expenses.reduce(0) { $0 + $1.amount })
        }
        .sorted { $0.amount > $1.amount }
    }
    
    private var highestSpendingDay: PeakSpendingDay? {
        peakSpendingDays.first
    }
    
    private var lowestSpendingDay: PeakSpendingDay? {
        peakSpendingDays.last
    }
    
    private func peakPercentage(for amount: Double) -> String {
        guard currentPeriodTotal > 0 else { return "—" }
        let share = (amount / currentPeriodTotal) * 100
        return String(format: "%.1f%%", share)
    }
    
    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "today".localized
        } else if calendar.isDateInYesterday(date) {
            return "yesterday".localized
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
    }
    
    private func groupExpensesByCategory(_ expenses: [Expense]) -> [UserCategory: Double] {
        var groups: [UserCategory: Double] = [:]
        for expense in expenses {
            let category = dataManager.resolveCategory(id: expense.categoryId)
            groups[category, default: 0] += expense.amount
        }
        return groups
    }
}

// MARK: - Card style

private struct AnalyticsCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
    }
}

private extension View {
    func cardStyle() -> some View { modifier(AnalyticsCard()) }
}

// MARK: - Supporting Views

struct CategoryBudgetRow: View {
    let budget: CategoryBudget
    @ObservedObject private var dataManager = DataManager.shared
    
    private var spentAmount: Double {
        let calendar = Calendar.current
        let now = Date()
        return dataManager.expenses.filter { expense in
            calendar.isDate(expense.date, equalTo: now, toGranularity: .month) && expense.categoryId == budget.categoryId
        }.reduce(0) { $0 + $1.amount }
    }
    
    private var progress: Double {
        guard budget.amount > 0 else { return 0 }
        return min(spentAmount / budget.amount, 1.0)
    }
    
    private var categoryInfo: (name: String, icon: String) {
        let category = dataManager.resolveCategory(id: budget.categoryId)
        return (category.name, category.iconSystemName)
    }
    
    private var progressColor: Color {
        if progress >= 1.0 { return .red }
        if progress > 0.8 { return .orange }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(categoryInfo.name, systemImage: categoryInfo.icon)
                    .font(.subheadline)

                Spacer()

                Text("\(CurrencyFormatter.format(spentAmount, currency: dataManager.user.currency)) / \(CurrencyFormatter.format(budget.amount, currency: dataManager.user.currency))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(progressColor)
        }
    }
}

struct DailySpendingPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

struct PeakSpendingDay: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

#Preview {
    AnalyticsView()
}
