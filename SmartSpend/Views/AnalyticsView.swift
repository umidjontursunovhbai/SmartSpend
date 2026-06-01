import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @State private var selectedTimeframe: TimeFrame = .month
    @State private var periodOffset: Int = 0  // 0 = current, 1 = previous, ...
    @State private var compareOption: CompareOption = .previousPeriod
    @State private var showingBudgetSettings = false


    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"

        var localizedName: String {
            switch self {
            case .week:  return "timeframe_week".localized
            case .month: return "timeframe_month".localized
            case .year:  return "timeframe_year".localized
            }
        }
    }

    enum CompareOption: Hashable {
        case previousPeriod   // immediately prior week/month/year
        case sameLastYear     // same window one year earlier

        var localizedName: String {
            switch self {
            case .previousPeriod: return "compare_previous_period".localized
            case .sameLastYear:   return "compare_same_last_year".localized
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    timeFramePicker
                    periodNavigator
                    comparePicker
                    spendingHighlights
                    if hasAnyHistoricalData { monthlyHistoryCard }
                    if hasAnyHistoricalData { yearOverYearCard }
                    spendingTrendSection
                    categoryBreakdownSection
                    categoryBudgetSection
                    peakSpendingDaysSection
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .onChange(of: selectedTimeframe) { _, _ in periodOffset = 0 }
            .onChange(of: selectedTimeframe) { _, _ in
                // Year-over-year picker doesn't really make sense on Year
                if selectedTimeframe == .year { compareOption = .previousPeriod }
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

    // MARK: - Period navigator (‹ May 2026 ›)

    private var periodNavigator: some View {
        HStack(spacing: 0) {
            Button { stepPeriod(by: 1) } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)

            Spacer()

            Button {
                if periodOffset != 0 { periodOffset = 0 }
            } label: {
                VStack(spacing: 2) {
                    Text(periodLabel(for: periodOffset))
                        .font(.headline)
                    if periodOffset != 0 {
                        Text("tap_to_return_today".localized)
                            .font(.caption2)
                            .foregroundStyle(.tint)
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button { stepPeriod(by: -1) } label: {
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(canStepForward ? Color.accentColor : Color.secondary)
            .disabled(!canStepForward)
        }
    }

    // MARK: - Compare picker (Compare to: Previous period ▾)

    @ViewBuilder
    private var comparePicker: some View {
        // Year-over-year only makes sense when at least 1 year of data exists,
        // and we hide the picker entirely on the Year timeframe.
        let showYoY = selectedTimeframe != .year && hasAnyHistoricalData

        if showYoY {
            HStack(spacing: 6) {
                Text("compare_to".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Menu {
                    Picker("compare_to".localized, selection: $compareOption) {
                        Text(CompareOption.previousPeriod.localizedName)
                            .tag(CompareOption.previousPeriod)
                        Text(CompareOption.sameLastYear.localizedName)
                            .tag(CompareOption.sameLastYear)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(compareOption.localizedName)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                    .font(.subheadline)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - 12-month history bar chart

    private var monthlyHistoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("monthly_history".localized)

            Chart {
                ForEach(last12Months) { bar in
                    BarMark(
                        x: .value("Month", bar.label),
                        y: .value("Amount", bar.amount)
                    )
                    .foregroundStyle(bar.isCurrent ? Color.accentColor : Color.accentColor.opacity(0.35))
                    .cornerRadius(4)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisValueLabel().font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine().foregroundStyle(Color(.systemGray5))
                    AxisValueLabel {
                        if let raw = value.as(Double.self) {
                            Text(CurrencyFormatter.formatCompact(raw, currency: dataManager.user.currency))
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 160)

            // Show month picker hint when bars are tappable in .month mode
            if selectedTimeframe == .month {
                Text("tap_month_hint".localized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .cardStyle()
    }

    // MARK: - Year-over-year card

    @ViewBuilder
    private var yearOverYearCard: some View {
        let currency = dataManager.user.currency
        let pct: Double? = sameDayLastYearTotal > 0
            ? ((yearToDateTotal - sameDayLastYearTotal) / sameDayLastYearTotal) * 100
            : nil

        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("year_to_date".localized)
            HStack(alignment: .firstTextBaseline) {
                Text(CurrencyFormatter.format(yearToDateTotal, currency: currency))
                    .font(.title2.weight(.semibold))
                    .fontDesign(.rounded)
                Spacer()
                if let pct {
                    HStack(spacing: 3) {
                        Image(systemName: pct >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(String(format: "%.1f%%", abs(pct)))
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(pct >= 0 ? Color.green : Color.red)
                }
            }
            if sameDayLastYearTotal > 0 {
                Text(String(format: "vs_last_year_format".localized,
                            CurrencyFormatter.format(sameDayLastYearTotal, currency: currency)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("no_last_year_data".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    private var spendingHighlights: some View {
        VStack(spacing: 0) {
            // Primary metric
            VStack(alignment: .leading, spacing: 6) {
                Text(periodLabel(for: periodOffset).uppercased())
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
                    .foregroundStyle(spendingChangePercentage >= 0 ? Color.green : Color.red)

                    // Show the comparison total so the percentage isn't floating
                    // — the user sees both periods spelled out.
                    Text(String(format: "comparison_total_format".localized,
                                comparisonPeriodLabel,
                                CurrencyFormatter.format(previousPeriodTotal, currency: dataManager.user.currency)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

    @ViewBuilder
    private var categoryBudgetSection: some View {
        let activeBudgets = dataManager.categoryBudgets.filter { $0.isEnabled && $0.amount > 0 }
        if !activeBudgets.isEmpty {
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

                VStack(spacing: 16) {
                    ForEach(activeBudgets) { budget in
                        CategoryBudgetRow(budget: budget)
                    }
                }
            }
            .cardStyle()
        }
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
                            Capsule().fill(spendingChangePercentage >= 0 ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                        )
                        .foregroundStyle(spendingChangePercentage >= 0 ? Color.green : Color.red)
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
        expenses(for: selectedTimeframe, offset: periodOffset)
    }

    private func expensesForPreviousPeriod() -> [Expense] {
        guard let interval = comparisonInterval else { return [] }
        return dataManager.expenses.filter { interval.contains($0.date) }
    }

    private func expenses(for timeframe: TimeFrame, offset: Int) -> [Expense] {
        guard let interval = periodRange(for: timeframe, offset: offset) else { return [] }
        return dataManager.expenses.filter { interval.contains($0.date) }
    }

    /// Date interval the user is comparing the current period against.
    private var comparisonInterval: DateInterval? {
        let calendar = Calendar.current
        switch compareOption {
        case .previousPeriod:
            return periodRange(for: selectedTimeframe, offset: periodOffset + 1)
        case .sameLastYear:
            guard let current = periodRange(for: selectedTimeframe, offset: periodOffset),
                  let start = calendar.date(byAdding: .year, value: -1, to: current.start),
                  let end = calendar.date(byAdding: .year, value: -1, to: current.end) else { return nil }
            return DateInterval(start: start, end: end)
        }
    }

    /// Human-readable label for the comparison window (e.g. "Apr 2026" or "May 2025").
    private var comparisonPeriodLabel: String {
        let calendar = Calendar.current
        switch compareOption {
        case .previousPeriod:
            return periodLabel(for: periodOffset + 1)
        case .sameLastYear:
            guard let current = periodRange(for: selectedTimeframe, offset: periodOffset),
                  let lastYearStart = calendar.date(byAdding: .year, value: -1, to: current.start) else { return "" }
            let formatter = DateFormatter()
            switch selectedTimeframe {
            case .week:
                formatter.dateFormat = "MMM d, yyyy"
                return formatter.string(from: lastYearStart)
            case .month:
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: lastYearStart)
            case .year:
                formatter.dateFormat = "yyyy"
                return formatter.string(from: lastYearStart)
            }
        }
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
        case .year:
            guard let referenceDate = calendar.date(byAdding: .year, value: -offset, to: now),
                  let interval = calendar.dateInterval(of: .year, for: referenceDate) else { return nil }
            return interval
        }
    }

    private var canStepForward: Bool { periodOffset > 0 }
    private func stepPeriod(by delta: Int) {
        // Pressing back (delta = +1) takes us further into the past.
        periodOffset = max(periodOffset + delta, 0)
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
        "\(periodLabel(for: periodOffset)) vs \(comparisonPeriodLabel)"
    }

    /// Just the percentage with arrow text; period name is rendered separately.
    private var trendPercentText: String {
        guard previousPeriodTotal > 0 else { return "no_change".localized }
        return "\(String(format: "%.1f%%", abs(spendingChangePercentage)))"
    }

    /// Full badge text, including the period it's compared against, so the user
    /// never has to wonder which two windows the percentage refers to.
    private var trendSummary: String {
        guard previousPeriodTotal > 0 else { return "no_change".localized }
        return String(format: "vs_period_pct_format".localized,
                      trendPercentText, comparisonPeriodLabel)
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
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: interval.start)
        }
    }

    // MARK: - 12-month history

    struct MonthBar: Identifiable {
        let id = UUID()
        let monthStart: Date
        let label: String
        let amount: Double
        let isCurrent: Bool
        let offset: Int
    }

    private var last12Months: [MonthBar] {
        let calendar = Calendar.current
        guard let now = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else { return [] }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var bars: [MonthBar] = []
        for offsetBack in (0..<12).reversed() {
            guard let monthStart = calendar.date(byAdding: .month, value: -offsetBack, to: now),
                  let interval = calendar.dateInterval(of: .month, for: monthStart) else { continue }
            let total = dataManager.expenses
                .filter { interval.contains($0.date) }
                .reduce(0) { $0 + $1.amount }
            bars.append(MonthBar(
                monthStart: monthStart,
                label: formatter.string(from: monthStart),
                amount: total,
                isCurrent: offsetBack == periodOffset && selectedTimeframe == .month,
                offset: offsetBack
            ))
        }
        return bars
    }

    private var yearToDateTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        guard let yearStart = calendar.dateInterval(of: .year, for: now)?.start else { return 0 }
        return dataManager.expenses
            .filter { $0.date >= yearStart && $0.date <= now }
            .reduce(0) { $0 + $1.amount }
    }

    private var sameDayLastYearTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        guard let lastYearSameDay = calendar.date(byAdding: .year, value: -1, to: now),
              let lastYearStart = calendar.dateInterval(of: .year, for: lastYearSameDay)?.start else { return 0 }
        return dataManager.expenses
            .filter { $0.date >= lastYearStart && $0.date <= lastYearSameDay }
            .reduce(0) { $0 + $1.amount }
    }

    private var hasAnyHistoricalData: Bool {
        last12Months.contains { $0.amount > 0 }
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
