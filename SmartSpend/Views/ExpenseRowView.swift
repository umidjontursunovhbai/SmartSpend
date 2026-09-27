import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    let categoryDisplayInfo: (name: String, icon: String, color: Color)
    let currency: Currency
    let isSelectionMode: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onDelete: () -> Void

    @State private var showingEditExpense = false

    var body: some View {
        Button(action: {
            if isSelectionMode {
                onToggleSelection()
            } else {
                showingEditExpense = true
            }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(width: iOSDesignSystem.Size.rowIcon, height: iOSDesignSystem.Size.rowIcon)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(categoryDisplayInfo.color.opacity(0.28), lineWidth: 1)
                        )
                    HeroIcon(systemName: categoryDisplayInfo.icon, size: 21)
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

                Text(formatCurrency(expense.amount))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .multilineTextAlignment(.trailing)

                if isSelectionMode {
                    selectionMark
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.vertical, iOSDesignSystem.Spacing.xSmall)
            .frame(minHeight: iOSDesignSystem.Size.minimumTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressEffectButtonStyle())
        .listRowInsets(EdgeInsets(top: iOSDesignSystem.Spacing.xSmall,
                                  leading: iOSDesignSystem.Spacing.screenMargin,
                                  bottom: iOSDesignSystem.Spacing.xSmall,
                                  trailing: iOSDesignSystem.Spacing.screenMargin))
        .contextMenu {
            Button(action: { showingEditExpense = true }) {
                HeroIconLabel(title: "Edit", systemName: "pencil")
            }
            Button(role: .destructive, action: {
                onDelete()
            }) {
                HeroIconLabel(title: "Delete", systemName: "trash")
            }
        }
        .sheet(isPresented: $showingEditExpense) {
            EditExpenseView(expense: expense)
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        return CurrencyFormatter.format(amount, currency: currency)
    }

    private var selectionMark: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? categoryDisplayInfo.color : Color(.systemGray3), lineWidth: 2)

            if isSelected {
                Circle()
                    .fill(categoryDisplayInfo.color)

                HeroIcon("check", size: 12)
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 24, height: 24)
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
