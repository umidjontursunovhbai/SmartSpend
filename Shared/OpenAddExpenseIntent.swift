import AppIntents
import Foundation
import WidgetKit

struct OpenAddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Add Expense"
    static var description = IntentDescription("Open SmartSpend to add a new expense.")
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = false

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { .foreground(.immediate) }

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.tursunov.SmartSpend") ?? UserDefaults.standard
        defaults.set(true, forKey: "openAddExpense")
        defaults.synchronize()
        NotificationCenter.default.post(name: .smartSpendOpenAddExpense, object: nil)
        return .result()
    }
}

extension Notification.Name {
    static let smartSpendOpenAddExpense = Notification.Name("SmartSpend.OpenAddExpense")
}

struct ExpenseCategoryEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Expense Category"
    static var defaultQuery = ExpenseCategoryQuery()

    let id: UUID
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct ExpenseCategoryQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [ExpenseCategoryEntity] {
        try QuickAddExpenseStore.categories()
            .filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [ExpenseCategoryEntity] {
        try QuickAddExpenseStore.categories()
    }
}

struct QuickAddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    static var description = IntentDescription(
        "Ask for the expense details and save it without opening SmartSpend."
    )
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = true

    @Parameter(title: "Name")
    var expenseTitle: String

    @Parameter(title: "Price")
    var amount: Double

    @Parameter(title: "Date")
    var date: Date

    @Parameter(title: "Category")
    var category: ExpenseCategoryEntity

    static var parameterSummary: some ParameterSummary {
        Summary(
            "Add \(\.$expenseTitle) for \(\.$amount) on \(\.$date) in \(\.$category)"
        )
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let title = expenseTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw QuickAddExpenseError.invalidTitle
        }

        guard amount.isFinite, amount > 0 else {
            throw QuickAddExpenseError.invalidAmount
        }

        try QuickAddExpenseStore.addExpense(
            title: title,
            amount: amount,
            categoryId: category.id,
            date: date
        )
        WidgetCenter.shared.reloadAllTimelines()

        return .result(dialog: "Expense added to SmartSpend.")
    }
}

struct SmartSpendAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickAddExpenseIntent(),
            phrases: [
                "Add an expense in \(.applicationName)",
                "Quick add an expense with \(.applicationName)",
                "Log an expense with \(.applicationName)"
            ],
            shortTitle: "Add Expense",
            systemImageName: "plus.circle.fill"
        )
    }

    static var shortcutTileColor: ShortcutTileColor { .blue }
}

private enum QuickAddExpenseError: LocalizedError {
    case invalidTitle
    case invalidAmount
    case categoriesUnavailable
    case storageUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidTitle:
            return "Enter a name for the expense."
        case .invalidAmount:
            return "Enter an amount greater than zero."
        case .categoriesUnavailable:
            return "Add a category in SmartSpend before using Quick Add."
        case .storageUnavailable:
            return "SmartSpend could not update your expenses."
        }
    }
}

private enum QuickAddExpenseStore {
    private static let suiteName = "group.com.tursunov.SmartSpend"

    static func categories() throws -> [ExpenseCategoryEntity] {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw QuickAddExpenseError.storageUnavailable
        }

        guard let data = defaults.data(forKey: "userCategories") else {
            throw QuickAddExpenseError.categoriesUnavailable
        }

        let categories = try JSONDecoder().decode([StoredCategory].self, from: data)
        guard !categories.isEmpty else {
            throw QuickAddExpenseError.categoriesUnavailable
        }

        return categories
            .map { ExpenseCategoryEntity(id: $0.id, name: $0.name) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func addExpense(
        title: String,
        amount: Double,
        categoryId: UUID,
        date: Date
    ) throws {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw QuickAddExpenseError.storageUnavailable
        }

        var expenses: [StoredExpense]
        if let data = defaults.data(forKey: "expenses") {
            do {
                expenses = try JSONDecoder().decode([StoredExpense].self, from: data)
            } catch {
                throw QuickAddExpenseError.storageUnavailable
            }
        } else {
            expenses = []
        }

        expenses.append(
            StoredExpense(
                id: UUID(),
                title: title,
                amount: amount,
                categoryId: categoryId,
                date: date,
                notionId: nil
            )
        )

        do {
            defaults.set(try JSONEncoder().encode(expenses), forKey: "expenses")
            defaults.set(Date(), forKey: "dataLastChangedAt")
        } catch {
            throw QuickAddExpenseError.storageUnavailable
        }
    }

    private struct StoredCategory: Codable {
        let id: UUID
        let name: String
    }

    private struct StoredExpense: Codable {
        let id: UUID
        let title: String
        let amount: Double
        let categoryId: UUID
        let date: Date
        let notionId: String?
    }
}
