import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    @ObservedObject private var dataManager = DataManager.shared
    @State private var showingEditExpense = false
    @Binding var isSelectionMode: Bool
    @Binding var selectedExpenses: Set<UUID>

    private var isSelected: Bool {
        selectedExpenses.contains(expense.id)
    }

    private var categoryDisplayInfo: (name: String, icon: String, color: Color) {
        let category = dataManager.resolveCategory(id: expense.categoryId)
        return (category.name, category.iconSystemName, category.color)
    }

    var body: some View {
        Button(action: {
            if isSelectionMode {
                toggleSelection()
            } else {
                showingEditExpense = true
            }
        }) {
            HStack(spacing: 14) {
                if isSelectionMode {
                    ZStack {
                        Circle()
                            .stroke(isSelected ? categoryDisplayInfo.color : Color(.systemGray3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        if isSelected {
                            Circle()
                                .fill(categoryDisplayInfo.color)
                                .frame(width: 24, height: 24)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.thinMaterial)
                        .frame(width: 46, height: 46)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(categoryDisplayInfo.color.opacity(0.28), lineWidth: 1)
                        )
                    Image(systemName: categoryDisplayInfo.icon)
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(categoryDisplayInfo.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(expense.title.isEmpty ? "Unnamed" : expense.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(categoryDisplayInfo.name)
                        .font(.system(size: 13))
                        .foregroundStyle(categoryDisplayInfo.color)
                }

                Spacer(minLength: 8)

                Text(formatCurrency(expense.amount, dataManager.user.currency))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressEffectButtonStyle())
        .listRowInsets(EdgeInsets(top: 4, leading: isSelectionMode ? 8 : 16, bottom: 4, trailing: 16))
        .contextMenu {
            Button(action: { showingEditExpense = true }) {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: {
                withAnimation {
                    dataManager.moveToDeletedExpenses(expense)
                }
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditExpense) {
            EditExpenseView(expense: expense)
        }
    }

    private func toggleSelection() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if isSelected {
                selectedExpenses.remove(expense.id)
            } else {
                selectedExpenses.insert(expense.id)
            }
        }
    }

    private func formatCurrency(_ amount: Double, _ currency: Currency) -> String {
        return CurrencyFormatter.format(amount, currency: currency)
    }
}

struct PressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
