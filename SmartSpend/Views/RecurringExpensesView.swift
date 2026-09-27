import SwiftUI

struct RecurringExpensesView: View {
    @ObservedObject private var dataManager = DataManager.shared

    @State private var showingAddRecurring = false
    @State private var selectedRecurring: RecurringExpense?
    @State private var isSelectionMode = false
    @State private var selectedRecurringExpenses: Set<UUID> = []
    @State private var filter: RecurringFilter = .all

    private enum RecurringFilter: CaseIterable, Identifiable {
        case all
        case active
        case inactive

        var id: Self { self }

        var title: String {
            switch self {
            case .all: return "all".localized
            case .active: return "active".localized
            case .inactive: return "inactive".localized
            }
        }
    }

    private var sortedRecurringExpenses: [RecurringExpense] {
        dataManager.recurringExpenses
            .filter { recurring in
                switch filter {
                case .all:
                    return true
                case .active:
                    return recurring.isActive && !recurring.isExpired
                case .inactive:
                    return !recurring.isActive || recurring.isExpired
                }
            }
            .sorted { lhs, rhs in
                let lhsIsActive = lhs.isActive && !lhs.isExpired
                let rhsIsActive = rhs.isActive && !rhs.isExpired

                if lhsIsActive != rhsIsActive {
                    return lhsIsActive
                }
                return lhs.nextDueDate < rhs.nextDueDate
            }
    }

    private var notifications: [RecurringExpenseNotification] {
        dataManager.getRecurringExpenseNotifications()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                if dataManager.recurringExpenses.isEmpty {
                    EmptyRecurringExpensesView {
                        showingAddRecurring = true
                    }
                } else {
                    recurringContent
                }
            }
            .background(iOSDesignSystem.appBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddRecurring) {
                AddRecurringExpenseView()
            }
            .sheet(item: $selectedRecurring) { recurring in
                EditRecurringExpenseView(recurringExpense: recurring)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if isSelectionMode {
                    selectionBar
                }
            }
            .onAppear {
                dataManager.processRecurringExpenses()
            }
        }
    }

    private var header: some View {
        AppScreenHeader("recurring".localized) {
            if isSelectionMode {
                Button("cancel".localized) {
                    endSelectionMode()
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(.systemBlue))
                .frame(minHeight: iOSDesignSystem.Size.minimumTapTarget)

                ActionIconButton(
                    icon: "trash",
                    style: .destructive(enabled: !selectedRecurringExpenses.isEmpty)
                ) {
                    deleteSelectedRecurring()
                }
            } else {
                if !dataManager.recurringExpenses.isEmpty {
                    ActionIconButton(icon: "check-circle", style: .secondary) {
                        withAnimation(.snappy(duration: 0.25)) {
                            isSelectionMode = true
                        }
                    }
                }

                ActionIconButton(icon: "plus", style: .primary) {
                    showingAddRecurring = true
                }
            }
        }
    }

    private var recurringContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if !notifications.isEmpty {
                    RecurringAttentionCard(notifications: notifications) {
                        dataManager.processRecurringExpenses()
                    }
                }

                filterControl

                if sortedRecurringExpenses.isEmpty {
                    filteredEmptyState
                } else {
                    recurringList
                }
            }
            .padding(.horizontal, iOSDesignSystem.Spacing.screenMargin)
            .padding(.top, 6)
            .padding(.bottom, iOSDesignSystem.Spacing.screenMargin)
        }
        .scrollIndicators(.hidden)
        .background(iOSDesignSystem.appBackground)
    }

    private var filterControl: some View {
        HStack(spacing: 5) {
            ForEach(RecurringFilter.allCases) { item in
                Button {
                    withAnimation(.snappy(duration: 0.24)) {
                        filter = item
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Text("\(recurringCount(for: item))")
                            .font(.caption2.weight(.bold).monospacedDigit())
                            .foregroundStyle(filter == item ? Color(.systemBlue) : Color.secondary)
                            .padding(.horizontal, 6)
                            .frame(minHeight: 20)
                            .background(
                                filter == item
                                    ? Color(.systemBlue).opacity(0.09)
                                    : Color(.tertiarySystemFill),
                                in: Capsule()
                            )
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(filter == item ? Color(.systemBlue) : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: iOSDesignSystem.Size.minimumTapTarget)
                    .background {
                        if filter == item {
                            Capsule()
                                .fill(Color(.systemBlue).opacity(0.075))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(.systemBlue).opacity(0.13), lineWidth: 1)
                                )
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.title), \(recurringCount(for: item))")
            }
        }
        .padding(4)
        .liquidGlassSurface(Capsule())
    }

    private var recurringList: some View {
        LazyVStack(spacing: 12) {
            ForEach(sortedRecurringExpenses) { recurring in
                RecurringExpenseCard(
                    recurringExpense: recurring,
                    categoryInfo: categoryDisplayInfo(for: recurring),
                    currency: dataManager.user.currency,
                    isSelectionMode: isSelectionMode,
                    isSelected: selectedRecurringExpenses.contains(recurring.id)
                )
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .onTapGesture {
                    if isSelectionMode {
                        toggleSelection(recurring)
                    } else {
                        selectedRecurring = recurring
                    }
                }
                .contextMenu {
                    if !isSelectionMode {
                        Button {
                            selectedRecurring = recurring
                        } label: {
                            Label("edit".localized, systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            withAnimation(.snappy(duration: 0.25)) {
                                dataManager.deleteRecurringExpense(recurring)
                            }
                        } label: {
                            Label("delete".localized, systemImage: "trash")
                        }
                    }
                }
                .accessibilityAddTraits(.isButton)
            }
        }
        .animation(.snappy(duration: 0.28), value: sortedRecurringExpenses.map(\.id))
    }

    private var filteredEmptyState: some View {
        VStack(spacing: 12) {
            HeroIcon(filter == .inactive ? "pause-circle" : "arrow-path", size: 27)
                .foregroundStyle(Color(.systemBlue))
                .frame(width: 54, height: 54)
                .background(Color(.systemBlue).opacity(0.08), in: Circle())

            Text("no_recurring_expenses".localized)
                .font(.headline)

            Text("set_up_recurring_expenses".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .padding(.vertical, 54)
    }

    private var selectionBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "selected_count".localized, selectedRecurringExpenses.count))
                    .font(.headline)

                Text("recurring_expenses_title".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                deleteSelectedRecurring()
            } label: {
                HeroIcon("trash", size: 21)
                    .foregroundStyle(selectedRecurringExpenses.isEmpty ? Color(.systemGray3) : Color(.systemRed))
                    .frame(width: 44, height: 44)
                    .background(
                        Color(.systemRed).opacity(selectedRecurringExpenses.isEmpty ? 0.04 : 0.09),
                        in: Circle()
                    )
            }
            .buttonStyle(.plain)
            .disabled(selectedRecurringExpenses.isEmpty)
        }
        .padding(.leading, 18)
        .padding(.trailing, 10)
        .padding(.vertical, 8)
        .liquidGlassSurface(Capsule())
        .padding(.horizontal, iOSDesignSystem.Spacing.screenMargin)
        .padding(.bottom, iOSDesignSystem.Spacing.small)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func recurringCount(for filter: RecurringFilter) -> Int {
        dataManager.recurringExpenses.reduce(into: 0) { count, recurring in
            let isActive = recurring.isActive && !recurring.isExpired

            switch filter {
            case .all:
                count += 1
            case .active where isActive:
                count += 1
            case .inactive where !isActive:
                count += 1
            default:
                break
            }
        }
    }

    private func categoryDisplayInfo(for recurring: RecurringExpense) -> RecurringCategoryInfo {
        let category = dataManager.resolveCategory(id: recurring.categoryId)
        return RecurringCategoryInfo(
            name: category.name,
            icon: category.iconSystemName,
            color: category.color
        )
    }

    private func toggleSelection(_ recurring: RecurringExpense) {
        withAnimation(.snappy(duration: 0.2)) {
            if selectedRecurringExpenses.contains(recurring.id) {
                selectedRecurringExpenses.remove(recurring.id)
            } else {
                selectedRecurringExpenses.insert(recurring.id)
            }
        }
    }

    private func endSelectionMode() {
        withAnimation(.snappy(duration: 0.25)) {
            isSelectionMode = false
            selectedRecurringExpenses.removeAll()
        }
    }

    private func deleteSelectedRecurring() {
        guard !selectedRecurringExpenses.isEmpty else { return }

        withAnimation(.snappy(duration: 0.28)) {
            for recurring in dataManager.recurringExpenses where selectedRecurringExpenses.contains(recurring.id) {
                dataManager.deleteRecurringExpense(recurring)
            }
            selectedRecurringExpenses.removeAll()
            isSelectionMode = false
        }
    }
}

private struct RecurringCategoryInfo {
    let name: String
    let icon: String
    let color: Color
}

private struct RecurringAttentionCard: View {
    let notifications: [RecurringExpenseNotification]
    let process: () -> Void

    private var primaryNotification: RecurringExpenseNotification? {
        notifications.first
    }

    private var hasOverdue: Bool {
        notifications.contains { notification in
            if case .overdue = notification.type { return true }
            return false
        }
    }

    private var tint: Color {
        hasOverdue ? Color(.systemRed) : Color(.systemOrange)
    }

    var body: some View {
        HStack(spacing: 12) {
            HeroIcon(hasOverdue ? "exclamation-triangle" : "bell", size: 20)
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.09), in: Circle())
                .overlay(alignment: .topTrailing) {
                    if notifications.count > 1 {
                        Text("\(notifications.count)")
                            .font(.caption2.weight(.bold).monospacedDigit())
                            .foregroundStyle(.white)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(tint, in: Circle())
                    }
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(primaryNotification?.recurringExpense.title ?? "upcoming_bills".localized)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(primaryNotification.map { relativeDueText(for: $0.recurringExpense.nextDueDate) } ?? "")
                    .font(.caption)
                    .foregroundStyle(tint)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button("process".localized, action: process)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .padding(.horizontal, 12)
                .frame(minHeight: iOSDesignSystem.Size.minimumTapTarget)
                .background(tint.opacity(0.08), in: Capsule())
                .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: tint.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

private struct RecurringExpenseCard: View {
    let recurringExpense: RecurringExpense
    let categoryInfo: RecurringCategoryInfo
    let currency: Currency
    let isSelectionMode: Bool
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(categoryInfo.color.opacity(0.10))

                        HeroIcon(systemName: categoryInfo.icon, size: 22)
                            .foregroundStyle(categoryInfo.color)
                    }
                    .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(recurringExpense.title.isEmpty ? categoryInfo.name : recurringExpense.title)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        HStack(spacing: 7) {
                            Text(categoryInfo.name)
                                .lineLimit(1)

                            Circle()
                                .fill(statusColor)
                                .frame(width: 5, height: 5)

                            Text(statusText)
                                .lineLimit(1)
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 4)

                    Text(CurrencyFormatter.format(recurringExpense.amount, currency: currency))
                        .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                        .multilineTextAlignment(.trailing)
                }

                Divider()
                    .overlay(Color(.separator).opacity(0.16))

                HStack(spacing: 10) {
                    Capsule()
                        .fill(statusColor)
                        .frame(width: 3, height: 34)

                    HeroIcon("calendar", size: 18)
                        .foregroundStyle(statusColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(relativeDueText(for: recurringExpense.nextDueDate))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(statusColor)
                            .lineLimit(1)

                        Text(exactDueDateText(for: recurringExpense.nextDueDate))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    HStack(spacing: 6) {
                        HeroIcon(systemName: recurringExpense.recurrenceType.icon, size: 13)
                        Text(recurringExpense.recurrenceType.rawValue)
                            .lineLimit(1)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(categoryInfo.color)
                    .padding(.horizontal, 9)
                    .frame(minHeight: 30)
                    .background(categoryInfo.color.opacity(0.075), in: Capsule())
                }
            }

            if isSelectionMode {
                selectionMark
                    .padding(.top, 11)
                    .padding(.trailing, iOSDesignSystem.Spacing.small)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isSelected ? Color(.systemBlue).opacity(0.48) : Color(.separator).opacity(0.14),
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .shadow(color: categoryInfo.color.opacity(0.035), radius: 12, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.025), radius: 3, x: 0, y: 1)
        .scaleEffect(isSelected ? 0.985 : 1)
        .animation(.snappy(duration: 0.2), value: isSelected)
        .accessibilityElement(children: .combine)
    }

    private var selectionMark: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color(.systemBlue) : Color(.systemGray3), lineWidth: 2)
                .frame(width: 24, height: 24)

            if isSelected {
                Circle()
                    .fill(Color(.systemBlue))
                    .frame(width: 24, height: 24)

                HeroIcon("check", size: 12)
                    .foregroundStyle(.white)
            }
        }
    }

    private var statusColor: Color {
        dueColor(for: recurringExpense)
    }

    private var statusText: String {
        if !recurringExpense.isActive {
            return "inactive".localized
        } else if recurringExpense.isExpired {
            return "expired".localized
        } else if recurringExpense.isOverdue {
            return "overdue".localized
        } else if recurringExpense.isDue {
            return "due".localized
        } else {
            return "active".localized
        }
    }
}

struct EmptyRecurringExpensesView: View {
    let addAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 44)

            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.systemBlue).opacity(0.08))
                    .frame(width: 84, height: 84)

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color(.systemBlue).opacity(0.12), lineWidth: 1)
                    .frame(width: 84, height: 84)

                HeroIcon("arrow-path", size: 34)
                    .foregroundStyle(Color(.systemBlue))
            }

            VStack(spacing: 9) {
                Text("no_recurring_expenses".localized)
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                Text("set_up_recurring_expenses".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 310)
            }

            Button(action: addAction) {
                HStack(spacing: 8) {
                    HeroIcon("plus", size: 18)
                    Text("add_recurring_expense".localized)
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(.systemBlue))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .liquidGlassSurface(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 320)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 28)
        .padding(.bottom, iOSDesignSystem.Spacing.large)
        .background(iOSDesignSystem.appBackground)
    }
}

private func relativeDueText(for date: Date) -> String {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let due = calendar.startOfDay(for: date)
    let days = calendar.dateComponents([.day], from: today, to: due).day ?? 0

    if days < 0 {
        return "\("overdue".localized) \(abs(days))d"
    } else if days == 0 {
        return "due_today".localized
    } else if days == 1 {
        return "due_tomorrow".localized
    } else {
        return String(format: "due_in_days_format".localized, days)
    }
}

private func exactDueDateText(for date: Date) -> String {
    date.formatted(date: .abbreviated, time: .omitted)
}

private func dueColor(for recurring: RecurringExpense) -> Color {
    if !recurring.isActive || recurring.isExpired {
        return Color(.systemGray)
    } else if recurring.isOverdue {
        return Color(.systemRed)
    } else if recurring.isDue {
        return Color(.systemOrange)
    } else {
        return Color(.systemGreen)
    }
}

#Preview {
    RecurringExpensesView()
}
