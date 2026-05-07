import WidgetKit
import SwiftUI

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
                return SmartSpendEntry.CategoryRow(id: cat.id, name: cat.name, icon: cat.iconSystemName,
                                                   colorName: cat.colorName, amount: amount)
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

// MARK: - Entry View (dispatches to size-specific views)

struct SmartSpendWidgetView: View {
    let entry: SmartSpendEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        case .systemLarge:  LargeWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: SmartSpendEntry

    private var budgetProgress: Double {
        guard entry.monthlySalary > 0 else { return 0 }
        return min(entry.monthTotal / entry.monthlySalary, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
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

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: SmartSpendEntry

    private var budgetProgress: Double {
        guard entry.monthlySalary > 0 else { return 0 }
        return min(entry.monthTotal / entry.monthlySalary, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text("SmartSpend")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(monthYearString())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(formatAmount(entry.todayTotal, code: entry.currencyCode))
                        .font(.title3.bold())
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                Spacer()
                Divider()
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("This Month")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(formatAmount(entry.monthTotal, code: entry.currencyCode))
                        .font(.title3.bold())
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }

            if entry.monthlySalary > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Budget")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        let remaining = entry.monthlySalary - entry.monthTotal
                        Text("\(formatAmount(remaining, code: entry.currencyCode)) left")
                            .font(.caption2)
                            .foregroundStyle(budgetProgress > 0.8 ? .red : .secondary)
                    }
                    ProgressView(value: budgetProgress)
                        .progressViewStyle(.linear)
                        .tint(budgetProgress > 0.8 ? .red : budgetProgress > 0.6 ? .orange : .green)
                }
            }
        }
        .padding()
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: SmartSpendEntry

    private var budgetProgress: Double {
        guard entry.monthlySalary > 0 else { return 0 }
        return min(entry.monthTotal / entry.monthlySalary, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
                Text("SmartSpend")
                    .font(.subheadline.bold())
                Spacer()
                Text(monthYearString())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatAmount(entry.todayTotal, code: entry.currencyCode))
                        .font(.title2.bold())
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("This Month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatAmount(entry.monthTotal, code: entry.currencyCode))
                        .font(.title2.bold())
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }

            if entry.monthlySalary > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Budget")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(budgetProgress * 100))% used")
                            .font(.caption)
                            .foregroundStyle(budgetProgress > 0.8 ? .red : .secondary)
                    }
                    ProgressView(value: budgetProgress)
                        .progressViewStyle(.linear)
                        .tint(budgetProgress > 0.8 ? .red : budgetProgress > 0.6 ? .orange : .green)
                }
            }

            if !entry.topCategories.isEmpty {
                Divider()
                Text("Top Categories")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                ForEach(entry.topCategories) { cat in
                    HStack {
                        Image(systemName: cat.icon)
                            .foregroundStyle(colorFromName(cat.colorName))
                            .frame(width: 24)
                        Text(cat.name)
                            .font(.subheadline)
                        Spacer()
                        Text(formatAmount(cat.amount, code: entry.currencyCode))
                            .font(.subheadline.bold())
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
