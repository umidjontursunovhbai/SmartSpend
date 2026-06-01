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
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var spendingHighlights: some View {
        VStack(spacing: 12) {
            // Hero card — primary metric
            VStack(alignment: .leading, spacing: 8) {
                Label("spent".localized, systemImage: "banknote.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
                Text(CurrencyFormatter.format(currentPeriodTotal, currency: dataManager.user.currency))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if previousPeriodTotal > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: spendingChangePercentage >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.bold())
                        Text(trendSummary)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.15), in: Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(.systemBlue), Color(.systemIndigo)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )

            // Secondary stats row
            HStack(spacing: 12) {
                miniHighlightCard(
                    title: "daily_avg".localized,
                    value: CurrencyFormatter.format(averageDailySpend, currency: dataManager.user.currency),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
                miniHighlightCard(
                    title: "Transactions",
                    value: "\(expensesCount)",
                    icon: "list.bullet.rectangle.portrait.fill",
                    color: .teal
                )
            }
        }
    }

    private func miniHighlightCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.bold())
                    .fontDesign(.rounded)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("category_breakdown".localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            if currentPeriodExpenses.isEmpty {
                Text("no_expenses_found".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            } else {
                let data = groupExpensesByCategory(currentPeriodExpenses)
                HStack(spacing: 20) {
                    Chart {
                        ForEach(Array(data.keys), id: \.id) { category in
                            SectorMark(
                                angle: .value("Amount", data[category] ?? 0),
                                innerRadius: .ratio(0.618),
                                angularInset: 1.5
                            )
                            .cornerRadius(4)
                            .foregroundStyle(by: .value("Category", category.name))
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(width: 140, height: 140)
                    .overlay {
                        VStack {
                            Text("\(categoriesUsedCount)")
                                .font(.title3.bold())
                                .fontDesign(.rounded)
                            Text("categories".localized)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(data.keys.prefix(4)), id: \.id) { category in
                            HStack {
                                Circle().fill(category.color).frame(width: 8, height: 8)
                                Text(category.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(CurrencyFormatter.format(data[category] ?? 0, currency: dataManager.user.currency))
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var categoryBudgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("budget_progress".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("manage".localized) {
                    showingBudgetSettings = true
                }
                .font(.subheadline)
                .foregroundStyle(.tint)
            }
            
            LazyVStack(spacing: 12) {
                let activeBudgets = dataManager.categoryBudgets.filter { $0.isEnabled }
                ForEach(activeBudgets) { budget in
                    CategoryBudgetRow(budget: budget)
                }
                
                if activeBudgets.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "target")
                            .font(.system(size: 30))
                            .foregroundStyle(.secondary)
                        Text("no_budget_set".localized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var spendingTrendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("spending_trends".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(trendSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(trendSummary)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(spendingChangePercentage >= 0 ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                    )
                    .foregroundStyle(spendingChangePercentage >= 0 ? Color.red : Color.green)
            }
                        
            if dailySpendingPoints.isEmpty {
                Text("no_expenses_found".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            } else {
                Chart {
                    ForEach(dailySpendingPoints) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(Color.accentColor.gradient.opacity(0.25))
                        
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(Color.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                        .interpolationMethod(.catmullRom)
                        
                        if point.date == highestSpendingDay?.date {
                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("Amount", point.amount)
                            )
                            .foregroundStyle(Color.red)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: selectedTimeframe == .week ? 7 : 5))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 220)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var peakSpendingDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("peak_days".localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(Array(peakSpendingDays.prefix(3).enumerated()), id: \.offset) { index, day in
                HStack(spacing: 12) {
                    VStack {
                        Text("#\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor, in: Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dayLabel(for: day.date))
                            .font(.subheadline.weight(.semibold))
                        Text(day.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(CurrencyFormatter.format(day.amount, currency: dataManager.user.currency))
                            .font(.subheadline.weight(.semibold))
                        Text(peakPercentage(for: day.amount))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(categoryInfo.name, systemImage: categoryInfo.icon)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(CurrencyFormatter.format(spentAmount, currency: dataManager.user.currency)) / \(CurrencyFormatter.format(budget.amount, currency: dataManager.user.currency))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(progress > 0.8 ? .red : .primary)
                }
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: progress > 1.0 ? .red : progress > 0.8 ? .orange : .green))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
        .padding(.vertical, 8)
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
