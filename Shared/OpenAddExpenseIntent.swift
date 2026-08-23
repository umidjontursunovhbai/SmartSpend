import AppIntents
import Foundation

struct OpenAddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    static var description = IntentDescription("Open SmartSpend to add a new expense.")
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = true

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.tursunov.SmartSpend") ?? UserDefaults.standard
        defaults.set(true, forKey: "openAddExpense")
        defaults.synchronize()
        return .result()
    }
}
