import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct SmartSpendControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.tursunov.SmartSpend.AddExpense") {
            ControlWidgetButton(action: OpenAddExpenseIntent()) {
                Label("Add Expense", systemImage: "banknote.fill")
            }
        }
        .displayName("Add Expense")
        .description("Quickly log a new expense in SmartSpend")
    }
}

struct OpenAddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.tursunov.SmartSpend") ?? UserDefaults.standard
        defaults.set(true, forKey: "openAddExpense")
        return .result()
    }
}
