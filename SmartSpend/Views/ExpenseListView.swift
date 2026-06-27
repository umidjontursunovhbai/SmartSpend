import SwiftUI

struct ExpenseListView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @State private var searchText = ""
    @State private var selectedCategoryIds: Set<String> = []
    @State private var selectedTimePeriod: TimePeriod = .all
    @State private var selectedCustomMonth: Date = Date()
    @State private var selectedStartDate: Date = Date()
    @State private var selectedEndDate: Date = Date()
    @State private var showingMonthPicker = false
    @State private var showingAddExpense = false
    @State private var showingFilterSheet = false
    @State private var isDateRangeMode = true
    @State private var isSelectionMode = false
    @State private var selectedExpenses: Set<UUID> = []

    enum TimePeriod: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case yesterday = "Yesterday"
        case weekly = "This Week"
        case monthly = "This Month"
        case customMonth = "Custom Month"

        var icon: String {
            switch self {
            case .all: return "calendar"
            case .today: return "calendar.badge.exclamationmark"
            case .yesterday: return "calendar.badge.minus"
            case .weekly: return "calendar.badge.clock"
            case .monthly: return "calendar.badge.plus"
            case .customMonth: return "calendar.badge.clock"
            }
        }

        var localizedName: String {
            switch self {
            case .all:
                return "time_period_all".localized
            case .today:
                return "time_period_today".localized
            case .yesterday:
                return "yesterday".localized
            case .weekly:
                return "time_period_this_week".localized
            case .monthly:
                return "time_period_this_month".localized
            case .customMonth:
                return "time_period_custom".localized
            }
        }
    }
    
    // Unified category model for filter
    struct FilterCategory: Hashable {
        let id: String
        let name: String
        let icon: String
        let color: Color
    }
    
    var availableFilterCategories: [FilterCategory] {
        var filters: [FilterCategory] = []
        
        // Add User Categories that are used or exist
        for category in dataManager.userCategories {
            filters.append(FilterCategory(
                id: category.id.uuidString,
                name: category.name,
                icon: category.iconSystemName,
                color: category.color
            ))
        }
        
        return filters.sorted { $0.name < $1.name }
    }
    
    var filteredExpenses: [Expense] {
        var expenses = dataManager.expenses.sorted { $0.date > $1.date }
        
        // Apply time period filter
        expenses = expenses.filter { expense in
            switch selectedTimePeriod {
            case .all:
                return true
            case .today:
                return Calendar.current.isDateInToday(expense.date)
            case .yesterday:
                return Calendar.current.isDateInYesterday(expense.date)
            case .weekly:
                let calendar = Calendar.current
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                return expense.date >= startOfWeek
            case .monthly:
                let calendar = Calendar.current
                let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
                return expense.date >= startOfMonth
            case .customMonth:
                let calendar = Calendar.current
                if isDateRangeMode {
                    return expense.date >= selectedStartDate && expense.date <= selectedEndDate
                } else {
                    return calendar.isDate(expense.date, inSameDayAs: selectedStartDate)
                }
            }
        }

        if !searchText.isEmpty {
            expenses = expenses.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }

        // Multi-category filter — empty set means "all categories"
        if !selectedCategoryIds.isEmpty {
            expenses = expenses.filter { selectedCategoryIds.contains($0.categoryId.uuidString) }
        }

        return expenses
    }

    var groupedExpenses: [(date: Date, expenses: [Expense], total: Double)] {
        let calendar = Calendar.current
        let dict = Dictionary(grouping: filteredExpenses) { expense in
            calendar.startOfDay(for: expense.date)
        }
        return dict.map { date, dayExpenses in
            let sorted = dayExpenses.sorted { $0.date > $1.date }
            return (date: date, expenses: sorted, total: sorted.reduce(0) { $0 + $1.amount })
        }
        .sorted { $0.date > $1.date }
    }

    private func sectionDateLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        let isCurrentYear = calendar.component(.year, from: date) == calendar.component(.year, from: Date())
        formatter.dateFormat = isCurrentYear ? "EEEE, MMM d" : "EEEE, MMM d, yyyy"
        return formatter.string(from: date)
    }

    private var isFilterActive: Bool {
        selectedTimePeriod != .all || !selectedCategoryIds.isEmpty
    }

    private func customRangeText() -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return "\(f.string(from: selectedStartDate)) – \(f.string(from: selectedEndDate))"
    }

    // Size the filter sheet to its content: short for a few categories, taller
    // as more are added, but capped at ~90% so it never jumps to full unless the
    // list genuinely needs it (then it scrolls and can be dragged up to .large).
    private var filterSheetDetents: Set<PresentationDetent> {
        let rows = max(availableFilterCategories.count, 1)
        // nav bar + time section + category header/footer + rows
        let estimated: CGFloat = 56 + 100 + 80 + CGFloat(rows) * 44 + 40
        let cap = UIScreen.main.bounds.height * 0.9
        return [.height(min(estimated, cap)), .large]
    }

    // The segmented control already exposes the quick time periods, so the
    // active-filter bar only needs to surface categories and custom ranges.
    private var showActiveFilterBar: Bool {
        selectedTimePeriod == .customMonth || !selectedCategoryIds.isEmpty
    }

    private var activeFilterSummary: String {
        var parts: [String] = []
        if selectedTimePeriod == .customMonth {
            parts.append(customRangeText())
        }
        let names = availableFilterCategories
            .filter { selectedCategoryIds.contains($0.id) }
            .map { $0.name }
        if names.count == 1 {
            parts.append(names[0])
        } else if names.count == 2 {
            parts.append("\(names[0]), \(names[1])")
        } else if names.count > 2 {
            parts.append("\(names[0]), \(names[1]) +\(names.count - 2)")
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Pinned quick time-period segmented control
                Picker("time_period".localized, selection: $selectedTimePeriod) {
                    Text("all".localized).tag(TimePeriod.all)
                    Text("time_period_today".localized).tag(TimePeriod.today)
                    Text("yesterday".localized).tag(TimePeriod.yesterday)
                    Text("timeframe_week".localized).tag(TimePeriod.weekly)
                    Text("timeframe_month".localized).tag(TimePeriod.monthly)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)

                // Small active-filter bar — only for "hidden" filters
                // (selected categories or a custom date range). Tapping the
                // summary reopens the filter sheet.
                if showActiveFilterBar {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .foregroundStyle(.tint)
                            Text(activeFilterSummary)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }

                // List / empty state
                if filteredExpenses.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(groupedExpenses, id: \.date) { group in
                            Section {
                                ForEach(group.expenses) { expense in
                                    ExpenseRowView(
                                        expense: expense,
                                        isSelectionMode: $isSelectionMode,
                                        selectedExpenses: $selectedExpenses
                                    )
                                }
                            } header: {
                                HStack {
                                    Text(sectionDateLabel(group.date))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .textCase(nil)
                                    Spacer()
                                    Text(CurrencyFormatter.format(group.total, currency: dataManager.user.currency))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.secondary)
                                        .textCase(nil)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("expenses".localized)
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "search_expenses".localized
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    leadingToolbarContent
                }
                ToolbarItem(placement: .topBarTrailing) {
                    trailingToolbarContent
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
            .sheet(isPresented: $showingFilterSheet) {
                ExpenseFilterSheet(
                    categories: availableFilterCategories,
                    selectedCategoryIds: selectedCategoryIds,
                    selectedTimePeriod: $selectedTimePeriod,
                    onApply: { categoryIds in
                        selectedCategoryIds = categoryIds
                    },
                    onPickCustomRange: {
                        showingFilterSheet = false
                        showingMonthPicker = true
                    },
                    onClear: { clearFilters() }
                )
                .presentationDetents(filterSheetDetents)
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingMonthPicker) {
                CalendarPickerView(
                    selectedStartDate: $selectedStartDate,
                    selectedEndDate: $selectedEndDate,
                    isDateRangeMode: $isDateRangeMode,
                    selectedTimePeriod: $selectedTimePeriod
                )
                .presentationDetents([.fraction(0.85)])
            }
            .overlay(alignment: .bottom) {
                selectionInfoBar
            }
        }
    }

    // MARK: - Empty state

    @ViewBuilder
    private var emptyState: some View {
        if !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if isFilterActive {
            ContentUnavailableView {
                Label("no_expenses_found".localized, systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text("try_adjusting_filters".localized)
            } actions: {
                Button("clear".localized) { clearFilters() }
            }
        } else {
            ContentUnavailableView {
                Label("no_expenses_found".localized, systemImage: "tray")
            } description: {
                Text("try_adjusting_filters".localized)
            } actions: {
                Button("add_expense".localized) { showingAddExpense = true }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func clearFilters() {
        withAnimation {
            selectedTimePeriod = .all
            selectedCategoryIds.removeAll()
        }
    }

    // MARK: - Toolbar Content

    private var filterButton: some View {
        Button {
            showingFilterSheet = true
        } label: {
            Image(systemName: isFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .font(.title3)
                .fontWeight(.medium)
        }
    }

    @ViewBuilder
    private var leadingToolbarContent: some View {
        if isSelectionMode {
            Button("cancel".localized) {
                withAnimation {
                    isSelectionMode = false
                    selectedExpenses.removeAll()
                }
            }
        } else {
            filterButton
        }
    }

    @ViewBuilder
    private var trailingToolbarContent: some View {
        if isSelectionMode {
            Button(action: deleteSelectedExpenses) {
                Image(systemName: "trash")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(selectedExpenses.isEmpty ? Color.secondary : Color.red)
            }
            .disabled(selectedExpenses.isEmpty)
        } else {
            HStack(spacing: 16) {
                if !dataManager.expenses.isEmpty {
                    Button(action: {
                        withAnimation {
                            isSelectionMode = true
                        }
                    }) {
                        Image(systemName: "checkmark.circle")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.blue)
                    }
                }

                Button(action: { showingAddExpense = true }) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.blue)
                }
            }
        }
    }
    
    @ViewBuilder
    private var selectionInfoBar: some View {
        if isSelectionMode && !selectedExpenses.isEmpty {
            HStack {
                Text("\(selectedExpenses.count) selected")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: selectAllExpenses) {
                    Text("Select All")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -2)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }


    private func selectAllExpenses() {
        withAnimation {
            selectedExpenses = Set(filteredExpenses.map { $0.id })
        }
    }
    
    private func deleteSelectedExpenses() {
        withAnimation {
            for expenseId in selectedExpenses {
                if let expense = dataManager.expenses.first(where: { $0.id == expenseId }) {
                    dataManager.moveToDeletedExpenses(expense)
                }
            }
            selectedExpenses.removeAll()
            isSelectionMode = false
        }
    }
}

struct CalendarPickerView: View {
    @Binding var selectedStartDate: Date
    @Binding var selectedEndDate: Date
    @Binding var isDateRangeMode: Bool
    @Binding var selectedTimePeriod: ExpenseListView.TimePeriod
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentMonth: Date = Date()
    @State private var selectionStep: SelectionStep = .startDate
    @State private var tempStartDate: Date = Date()
    @State private var tempEndDate: Date = Date()
    
    enum SelectionStep {
        case startDate
        case endDate
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header with Cancel and Done buttons
            HStack {
                Button("cancel".localized) {
                    dismiss()
                }
                .font(.body)
                .foregroundStyle(Color(.systemBlue))
                
                Spacer()
                
                Button("done".localized) {
                    selectedStartDate = tempStartDate
                    selectedEndDate = tempEndDate
                    selectedTimePeriod = .customMonth
                    dismiss()
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(selectionIsValid ? Color(.systemBlue) : Color(.systemGray))
                .disabled(!selectionIsValid)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .overlay(
                Divider()
                    .frame(maxHeight: .infinity, alignment: .bottom)
            )
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    calendarSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            currentMonth = selectedStartDate
            tempStartDate = selectedStartDate
            tempEndDate = selectedEndDate
            selectionStep = .startDate
            isDateRangeMode = true
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 18) {
            Text("custom_date_range".localized)
                .font(.title3.weight(.semibold))
            
            HStack(spacing: 14) {
                selectionCard(
                    title: "date_from".localized,
                    date: tempStartDate,
                    isActive: selectionStep == .startDate
                ) {
                    selectionStep = .startDate
                }
                
                selectionCard(
                    title: "date_to".localized,
                    date: tempEndDate,
                    isActive: selectionStep == .endDate
                ) {
                    selectionStep = .endDate
                }
            }
            
            rangeDetails
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
    }

    private func selectionCard(title: String, date: Date, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isActive ? Color(.systemBlue) : .secondary)
                Text(localizedDateString(from: date))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isActive ? Color(.systemBlue).opacity(0.12) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isActive ? Color(.systemBlue) : Color(.separator).opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var rangeDetails: some View {
        HStack {
            Label(rangeLengthText, systemImage: "arrow.left.and.right")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button(action: resetRange) {
                Text("reset".localized)
                    .font(.footnote.weight(.semibold))
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }

    private var rangeLengthText: String {
        let calendar = Calendar.current
        let dayDelta = calendar.dateComponents([.day], from: tempStartDate, to: tempEndDate).day ?? 0
        let totalDays = max(dayDelta, 0) + 1
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day]
        formatter.maximumUnitCount = 1
        return formatter.string(from: DateComponents(day: totalDays)) ?? "\(totalDays) d"
    }

    private func resetRange() {
        tempStartDate = selectedStartDate
        tempEndDate = selectedEndDate
        selectionStep = .startDate
    }

    private var calendarSection: some View {
        VStack(spacing: 20) {
            monthNavigation
            
            VStack(spacing: 12) {
                weekdayHeader
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                    ForEach(Array(calendarDays.enumerated()), id: \.offset) { _, date in
                        if let date = date {
                            CalendarDayView(
                                date: date,
                                state: dayState(for: date),
                                isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month),
                                action: { selectDate(date) }
                            )
                        } else {
                            Color.clear
                                .frame(height: 40)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 12)
        )
    }

    private var monthNavigation: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(.systemBlue))
                    .frame(width: 36, height: 36)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text(monthYearString(from: currentMonth))
                .font(.title3.weight(.semibold))
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(.systemBlue))
                    .frame(width: 36, height: 36)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
        }
    }
    
    private var weekdayHeader: some View {
        let symbols = weekdaySymbols
        return HStack(spacing: 0) {
            ForEach(symbols, id: \.self) { day in
                Text(day)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        
        var days: [Date?] = []
        let endDate = calendar.date(byAdding: .day, value: 41, to: startOfWeek) ?? startOfWeek
        
        var currentDate = startOfWeek
        while currentDate < endDate {
            if calendar.isDate(currentDate, equalTo: currentMonth, toGranularity: .month) {
                days.append(currentDate)
            } else {
                days.append(nil)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private func previousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    private func selectDate(_ date: Date) {
        switch selectionStep {
        case .startDate:
            tempStartDate = date
            if tempEndDate < tempStartDate {
                tempEndDate = tempStartDate
            }
            selectionStep = .endDate
        case .endDate:
            if date < tempStartDate {
                tempStartDate = date
                tempEndDate = date
                selectionStep = .endDate
            } else {
                tempEndDate = date
                selectionStep = .startDate
            }
        }
    }
    
    private func dayState(for date: Date) -> CalendarDayView.DayState {
        let calendar = Calendar.current
        let isStart = calendar.isDate(date, inSameDayAs: tempStartDate)
        let isEnd = calendar.isDate(date, inSameDayAs: tempEndDate)
        
        if isStart && isEnd {
            return .single
        } else if isStart {
            return .start
        } else if isEnd {
            return .end
        } else if date > tempStartDate && date < tempEndDate {
            return .inRange
        } else {
            return .none
        }
    }
    
    private var instructionText: String {
        switch selectionStep {
        case .startDate:
            return "date_range_instruction_first".localized
        case .endDate:
            return "date_range_instruction_second".localized
        }
    }

    private var selectionIsValid: Bool {
        tempEndDate >= tempStartDate
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
    
    private func localizedDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let symbols = formatter.shortWeekdaySymbols ?? ["S","M","T","W","T","F","S"]
        let calendar = Calendar.current
        let firstIndex = max(min(calendar.firstWeekday - 1, symbols.count - 1), 0)
        if firstIndex == 0 { return symbols }
        return Array(symbols[firstIndex...]) + Array(symbols[..<firstIndex])
    }
}

struct CalendarDayView: View {
    enum DayState {
        case none
        case inRange
        case start
        case end
        case single
    }
    
    let date: Date
    let state: DayState
    let isCurrentMonth: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                rangeBackground
                
                if showsSelection {
                    Circle()
                        .fill(Color(.systemBlue))
                        .frame(width: 40, height: 40)
                        .shadow(color: Color(.systemBlue).opacity(0.25), radius: 6, x: 0, y: 3)
                }
                
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: showsSelection ? .semibold : .regular))
                    .foregroundStyle(textColor)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }
    
    private var showsSelection: Bool {
        switch state {
        case .start, .end, .single:
            return true
        default:
            return false
        }
    }
    
    private var textColor: Color {
        if showsSelection {
            return .white
        } else if isCurrentMonth {
            return Color(.label)
        } else {
            return Color(.tertiaryLabel)
        }
    }
    
    private var rangeBackground: some View {
        Group {
            if state == .inRange {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemBlue).opacity(0.15))
                    .frame(width: 44, height: 32)
            } else {
                Color.clear
            }
        }
    }
}

// MARK: - Filter Sheet

struct ExpenseFilterSheet: View {
    let categories: [ExpenseListView.FilterCategory]
    @State private var draftCategoryIds: Set<String>
    @Binding var selectedTimePeriod: ExpenseListView.TimePeriod
    var onApply: (Set<String>) -> Void
    var onPickCustomRange: () -> Void
    var onClear: () -> Void

    @Environment(\.dismiss) private var dismiss

    init(
        categories: [ExpenseListView.FilterCategory],
        selectedCategoryIds: Set<String>,
        selectedTimePeriod: Binding<ExpenseListView.TimePeriod>,
        onApply: @escaping (Set<String>) -> Void,
        onPickCustomRange: @escaping () -> Void,
        onClear: @escaping () -> Void
    ) {
        self.categories = categories
        self._draftCategoryIds = State(initialValue: selectedCategoryIds)
        self._selectedTimePeriod = selectedTimePeriod
        self.onApply = onApply
        self.onPickCustomRange = onPickCustomRange
        self.onClear = onClear
    }

    private var hasActiveFilter: Bool {
        selectedTimePeriod != .all || !draftCategoryIds.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                // Time period — only custom range here; quick periods live in the
                // segmented control on the main screen.
                Section("time_period".localized) {
                    Button {
                        onApply(draftCategoryIds)
                        onPickCustomRange()
                    } label: {
                        HStack {
                            Label("custom_date_range".localized, systemImage: "calendar")
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedTimePeriod == .customMonth {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.tint)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                // Categories — multi select
                Section {
                    if categories.isEmpty {
                        Text("no_expenses_yet".localized)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(categories, id: \.id) { category in
                            Button {
                                toggle(category.id)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(category.color)
                                        .frame(width: 28)
                                    Text(category.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if draftCategoryIds.contains(category.id) {
                                        Image(systemName: "checkmark")
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.tint)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    HStack {
                        Text("category".localized)
                        Spacer()
                        if !draftCategoryIds.isEmpty {
                            Text("\(draftCategoryIds.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("filter_category_hint".localized)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("filter".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("clear".localized) {
                        withAnimation(.snappy) {
                            draftCategoryIds.removeAll()
                        }
                        onClear()
                    }
                        .disabled(!hasActiveFilter)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done".localized) {
                        onApply(draftCategoryIds)
                        dismiss()
                    }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func toggle(_ id: String) {
        withAnimation(.snappy) {
            if draftCategoryIds.contains(id) {
                draftCategoryIds.remove(id)
            } else {
                draftCategoryIds.insert(id)
            }
        }
    }
}

#Preview {
    ExpenseListView()
}
