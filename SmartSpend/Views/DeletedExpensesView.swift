import SwiftUI

struct DeletedExpensesView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredDeletedExpenses: [ArchivedExpense] {
        let sorted = dataManager.deletedExpenses.sorted { $0.archivedDate > $1.archivedDate }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredDeletedExpenses.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "no_deleted_expenses".localized : "no_deleted_expenses_found".localized,
                        systemImage: searchText.isEmpty ? "archivebox" : "magnifyingglass"
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredDeletedExpenses) { expense in
                        DeletedExpenseRowView(deletedExpense: expense)
                            .swipeActions(edge: .trailing) {
                                Button("delete_button".localized, role: .destructive) {
                                    dataManager.permanentlyDeleteExpense(expense)
                                }
                                Button("restore_button".localized) {
                                    dataManager.restoreExpense(expense)
                                }
                                .tint(.green)
                            }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "search_deleted_expenses".localized
            )
            .navigationTitle("deleted_expenses_title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done".localized) { dismiss() }
                }
            }
        }
    }
}

struct DeletedExpenseRowView: View {
    let deletedExpense: ArchivedExpense
    @ObservedObject private var dataManager = DataManager.shared
    
    // Helper to resolve the correct category display info
    private var categoryDisplayInfo: (name: String, icon: String, color: Color) {
        let category = dataManager.resolveCategory(id: deletedExpense.categoryId)
        return (category.name, category.iconSystemName, category.color)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: categoryDisplayInfo.icon)
                .foregroundStyle(categoryDisplayInfo.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(deletedExpense.title)
                    .lineLimit(1)
                Text(categoryDisplayInfo.name + " · " + deletedExpense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(deletedExpense.amount, dataManager.user.currency))
                    .fontWeight(.medium)
                let days = dataManager.getDaysRemainingForExpense(deletedExpense)
                Text(days > 0 ? "\(days)d left" : "Expired")
                    .font(.caption2)
                    .foregroundStyle(days <= 7 ? .red : .secondary)
            }
        }
        .foregroundStyle(.secondary)
    }
    
    private func formatCurrency(_ amount: Double, _ currency: Currency) -> String {
        return CurrencyFormatter.format(amount, currency: currency)
    }
}

#Preview {
    DeletedExpensesView()
}
