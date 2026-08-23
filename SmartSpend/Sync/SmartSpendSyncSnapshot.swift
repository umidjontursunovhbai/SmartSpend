import Foundation

struct SmartSpendSyncSnapshot: Codable {
    let schemaVersion: Int
    let updatedAt: Date
    var expenses: [Expense]
    var user: User
    var deletedExpenses: [ArchivedExpense]
    var categoryBudgets: [CategoryBudget]
    var spendingGoals: [SpendingGoal]
    var monthlySalaries: [MonthlySalary]
    var recurringExpenses: [RecurringExpense]
    var learnedPatterns: [LearnedPattern]
    var userCategories: [UserCategory]
    var customStartDate: Date
    var customEndDate: Date
}

enum CloudSyncState: Equatable {
    case idle
    case checking
    case syncing
    case synced(Date)
    case unavailable(String)
    case failed(String)

    var title: String {
        switch self {
        case .idle:
            return "Ready"
        case .checking:
            return "Checking iCloud"
        case .syncing:
            return "Syncing"
        case .synced:
            return "Synced"
        case .unavailable:
            return "Unavailable"
        case .failed:
            return "Sync Failed"
        }
    }

    var message: String {
        switch self {
        case .idle:
            return "Uses your iCloud account when CloudKit is enabled."
        case .checking:
            return "Checking your iCloud account status..."
        case .syncing:
            return "Keeping your SmartSpend data up to date."
        case .synced(let date):
            return "Last synced \(date.formatted(date: .abbreviated, time: .shortened))."
        case .unavailable(let reason), .failed(let reason):
            return reason
        }
    }
}
