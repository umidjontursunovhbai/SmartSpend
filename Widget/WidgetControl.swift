import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct SmartSpendControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.tursunov.SmartSpend.AddExpense") {
            ControlWidgetButton(action: OpenAddExpenseIntent()) {
                Label("Quick Add", systemImage: "plus.circle.fill")
            }
        }
        .displayName("SmartSpend Quick Add")
        .description("Open SmartSpend to add a new expense")
    }
}
