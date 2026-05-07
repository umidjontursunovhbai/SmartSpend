import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Lightweight mirror types for decoding app data

private let appGroupID = "group.muydinov.SmartSpend"

private struct WExpense: Codable {
    let amount: Double
    let categoryId: UUID
    let date: Date
}

private struct WUser: Codable {
    let currency: String
}

private struct WCategory: Codable {
    let id: UUID
    let name: String
    let iconSystemName: String
    let colorName: String
}

private struct WMonthlySalary: Codable {
    let month: Int
    let year: Int
    let amount: Double
}

// MARK: - Timeline Entry

struct SmartSpendEntry: TimelineEntry {
    let date: Date
    let todayTotal: Double
    let monthTotal: Double
    let monthlySalary: Double
    let currencyCode: String
    let topCategories: [CategoryRow]

    struct CategoryRow: Identifiable {
        let id: UUID
        let name: String
        let icon: String
        let colorName: String
        let amount: Double
    }

    static var placeholder: SmartSpendEntry {
        SmartSpendEntry(
            date: .now,
            todayTotal: 42.50,
            monthTotal: 350.00,
            monthlySalary: 1200.00,
            currencyCode: "USD",
            topCategories: [
                CategoryRow(id: UUID(), name: "Food", icon: "fork.knife", colorName: "systemGreen", amount: 120),
                CategoryRow(id: UUID(), name: "Transport", icon: "car.fill", colorName: "systemBlue", amount: 80),
                CategoryRow(id: UUID(), name: "Shopping", icon: "bag.fill", colorName: "systemPurple", amount: 65),
            ]
        )
    }
}

// MARK: - Timeline Provider

struct SmartSpendProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmartSpendEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (SmartSpendEntry) -> Void) {
        completion(context.isPreview ? .placeholder : loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmartSpendEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> SmartSpendEntry {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        let decoder = JSONDecoder()

        var expenses: [WExpense] = []
        if let data = defaults.data(forKey: "expenses"),
           let decoded = try? decoder.decode([WExpense].self, from: data) {
            expenses = decoded
        }

        var currencyCode = "USD"
        if let data = defaults.data(forKey: "user"),
           let decoded = try? decoder.decode(WUser.self, from: data) {
            currencyCode = decoded.currency
        }

        var categories: [WCategory] = []
        if let data = defaults.data(forKey: "userCategories"),
           let decoded = try? decoder.decode([WCategory].self, from: data) {
            categories = decoded
        }

        var salaries: [WMonthlySalary] = []
        if let data = defaults.data(forKey: "monthlySalaries"),
           let decoded = try? decoder.decode([WMonthlySalary].self, from: data) {
            salaries = decoded
        }

        let calendar = Calendar.current
        let now = Date()
        let nowComponents = calendar.dateComponents([.year, .month], from: now)
        let startOfMonth = calendar.date(from: nowComponents)!

        let todayTotal = expenses
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }

        let monthTotal = expenses
            .filter { $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }

        let monthlySalary = salaries
            .first { $0.month == nowComponents.month! && $0.year == nowComponents.year! }?.amount ?? 0

        let categoryDict = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        var catTotals: [UUID: Double] = [:]
        for expense in expenses where expense.date >= startOfMonth {
            catTotals[expense.categoryId, default: 0] += expense.amount
        }

        let topCategories = catTotals
            .sorted { $0.value > $1.value }
            .prefix(3)
            .compactMap { catId, amount -> SmartSpendEntry.CategoryRow? in
                guard let cat = categoryDict[catId] else { return nil }
                return SmartSpendEntry.CategoryRow(
                    id: cat.id, name: cat.name,
                    icon: cat.iconSystemName, colorName: cat.colorName, amount: amount
                )
            }

        return SmartSpendEntry(
            date: now,
            todayTotal: todayTotal,
            monthTotal: monthTotal,
            monthlySalary: monthlySalary,
            currencyCode: currencyCode,
            topCategories: topCategories
        )
    }
}

// MARK: - Root Entry View (dispatches by size)

struct SmartSpendWidgetView: View {
    let entry: SmartSpendEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:         SmallWidgetView(entry: entry)
        case .systemMedium:        MediumWidgetView(entry: entry)
        case .systemLarge:         LargeWidgetView(entry: entry)
        case .accessoryCircular:   AccessoryCircularView(entry: entry)
        case .accessoryRectangular:AccessoryRectangularView(entry: entry)
        case .accessoryInline:     AccessoryInlineView(entry: entry)
        default:                   SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Home Screen: Small

struct SmallWidgetView: View {
    let entry: SmartSpendEntry

    private var budgetProgress: Double {
        guard entry.monthlySalary > 0 else { return 0 }
        return min(entry.monthTotal / entry.monthlySalary, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "banknote.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text("SmartSpend")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Today")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(formatAmount(entry.todayTotal, code: entry.currencyCode))
                .font(.title2.bold())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            if entry.monthlySalary > 0 {
                ProgressView(value: budgetProgress)
                    .progressViewStyle(.linear)
                    .tint(budgetProgress > 0.8 ? .red : .green)
            }
        }
        .padding()
    }
}

// MARK: - Home Screen: Medium

struct MediumWidgetView: View {
    let entry: SmartSpendEntry

    private var budgetProgress: Double {
        guard entry.monthlySalary > 0 else { return 0 }
        return min(entry.monthTotal / entry.monthlySalary, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "banknote.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("SmartSpend")
                        .font(.caption.bold())
                }
                Spacer()
                Text(monthYearString())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: Capsule())
            }

            // Spending cards
            HStack(spacing: 8) {
                spendingCard(label: "TODAY", amount: entry.todayTotal, code: entry.currencyCode)
                spendingCard(label: "THIS MONTH", amount: entry.monthTotal, code: entry.currencyCode)
            }

            // Budget bar
            if entry.monthlySalary > 0 {
                HStack(spacing: 6) {
                    ProgressView(value: budgetProgress)
                        .progressViewStyle(.linear)
                        .tint(budgetProgress > 0.8 ? .red : budgetProgress > 0.6 ? .orange : .green)
                    let remaining = entry.monthlySalary - entry.monthTotal
                    Text("\(formatAmount(remaining, code: entry.currencyCode)) left")
                        .font(.caption2.bold())
                        .foregroundStyle(budgetProgress > 0.8 ? .red : .green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
        .padding(14)
    }

    private func spendingCard(label: String, amount: Double, code: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            Text(formatAmount(amount, code: code))
                .font(.system(size: 16, weight: .bold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Home Screen: Large

struct LargeWidgetView: View {
    let entry: SmartSpendEntry

    private var budgetProgress: Double {
        guard entry.monthlySalary > 0 else { return 0 }
        return min(entry.monthTotal / entry.monthlySalary, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ──────────────────────────────────────
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "banknote.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                    Text("SmartSpend")
                        .font(.subheadline.bold())
                }
                Spacer()
                Text(monthYearString())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            // ── Spending cards ───────────────────────────────
            HStack(spacing: 10) {
                bigSpendingCard(label: "TODAY", amount: entry.todayTotal)
                bigSpendingCard(label: "THIS MONTH", amount: entry.monthTotal)
            }
            .padding(.horizontal, 12)

            // ── Budget bar ───────────────────────────────────
            if entry.monthlySalary > 0 {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("BUDGET")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                        Spacer()
                        let remaining = entry.monthlySalary - entry.monthTotal
                        Text("\(formatAmount(remaining, code: entry.currencyCode)) remaining")
                            .font(.caption.bold())
                            .foregroundStyle(budgetProgress > 0.8 ? .red : .green)
                    }
                    ProgressView(value: budgetProgress)
                        .progressViewStyle(.linear)
                        .tint(budgetProgress > 0.8 ? .red : budgetProgress > 0.6 ? .orange : .green)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }

            // ── Add Expense quick-action button ─────────────
            Button(intent: OpenAddExpenseIntent()) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline)
                    Text("Add Expense")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.green.opacity(0.6))
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // ── Top categories ───────────────────────────────
            if !entry.topCategories.isEmpty {
                HStack {
                    Text("TOP SPENDING")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 6)

                VStack(spacing: 0) {
                    ForEach(Array(entry.topCategories.enumerated()), id: \.element.id) { index, cat in
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(colorFromName(cat.colorName).opacity(0.15))
                                    .frame(width: 30, height: 30)
                                Image(systemName: cat.icon)
                                    .foregroundStyle(colorFromName(cat.colorName))
                                    .font(.caption)
                            }
                            Text(cat.name)
                                .font(.subheadline)
                            Spacer()
                            Text(formatAmount(cat.amount, code: entry.currencyCode))
                                .font(.subheadline.bold())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)

                        if index < entry.topCategories.count - 1 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func bigSpendingCard(label: String, amount: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            Text(formatAmount(amount, code: entry.currencyCode))
                .font(.title3.bold())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Lock Screen: Circular
// Ring gauge showing monthly budget used; today's spending in the centre.
// Falls back to a compact amount + icon when no salary is set.

struct AccessoryCircularView: View {
    let entry: SmartSpendEntry

    private var budgetProgress: Double {
        guard entry.monthlySalary > 0 else { return 0 }
        return min(entry.monthTotal / entry.monthlySalary, 1.0)
    }

    var body: some View {
        if entry.monthlySalary > 0 {
            Gauge(value: budgetProgress) {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 9))
            } currentValueLabel: {
                VStack(spacing: 0) {
                    Text(compactAmount(entry.todayTotal))
                        .font(.system(size: 11, weight: .bold))
                        .minimumScaleFactor(0.5)
                    Text("today")
                        .font(.system(size: 7))
                }
            }
            .gaugeStyle(.accessoryCircular)
            .tint(budgetProgress > 0.8 ? .red : budgetProgress > 0.6 ? .orange : .green)
        } else {
            // No salary set — show a simple open ring with today's spending
            Gauge(value: 1) {
                EmptyView()
            } currentValueLabel: {
                VStack(spacing: 0) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 9))
                    Text(compactAmount(entry.todayTotal))
                        .font(.system(size: 11, weight: .bold))
                        .minimumScaleFactor(0.5)
                }
            }
            .gaugeStyle(.accessoryCircular)
        }
    }
}

// MARK: - Lock Screen: Rectangular
// Header with branding, then Today / Month rows and an optional budget bar.

struct AccessoryRectangularView: View {
    let entry: SmartSpendEntry

    private var budgetProgress: Double {
        guard entry.monthlySalary > 0 else { return 0 }
        return min(entry.monthTotal / entry.monthlySalary, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Branding row
            HStack(spacing: 3) {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 9, weight: .semibold))
                Text("SmartSpend")
                    .font(.system(size: 10, weight: .semibold))
            }

            // Today row
            HStack {
                Text("Today")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatAmount(entry.todayTotal, code: entry.currencyCode))
                    .font(.system(size: 11, weight: .bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }

            // Month row
            HStack {
                Text("Month")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatAmount(entry.monthTotal, code: entry.currencyCode))
                    .font(.system(size: 11, weight: .bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }

            // Budget progress bar (only when salary is set)
            if entry.monthlySalary > 0 {
                ProgressView(value: budgetProgress)
                    .progressViewStyle(.linear)
                    .tint(budgetProgress > 0.8 ? .red : budgetProgress > 0.6 ? .orange : .green)
            }
        }
    }
}

// MARK: - Lock Screen: Inline
// Single line above the clock

struct AccessoryInlineView: View {
    let entry: SmartSpendEntry

    var body: some View {
        Label {
            Text("Today: \(formatAmount(entry.todayTotal, code: entry.currencyCode))")
        } icon: {
            Image(systemName: "banknote.fill")
        }
    }
}

// MARK: - Helpers

private func formatAmount(_ amount: Double, code: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = code
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: amount)) ?? "\(code) \(String(format: "%.2f", amount))"
}

private func compactAmount(_ amount: Double) -> String {
    if amount >= 1_000_000 { return String(format: "%.0fM", amount / 1_000_000) }
    if amount >= 1_000    { return String(format: "%.0fK", amount / 1_000) }
    return String(format: "%.0f", amount)
}

private func monthYearString() -> String {
    let f = DateFormatter()
    f.dateFormat = "MMMM yyyy"
    return f.string(from: Date())
}

private func colorFromName(_ name: String) -> Color {
    switch name {
    case "systemRed":    return .red
    case "systemOrange": return .orange
    case "systemYellow": return .yellow
    case "systemGreen":  return .green
    case "systemMint":   return Color(.systemMint)
    case "systemTeal":   return .teal
    case "systemCyan":   return .cyan
    case "systemBlue":   return .blue
    case "systemIndigo": return .indigo
    case "systemPurple": return .purple
    case "systemPink":   return .pink
    case "systemBrown":  return .brown
    default:             return .blue
    }
}

// MARK: - Widget Declaration

struct SmartSpendWidget: Widget {
    let kind = "SmartSpendWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SmartSpendProvider()) { entry in
            SmartSpendWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("SmartSpend")
        .description("Track your spending at a glance.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}
