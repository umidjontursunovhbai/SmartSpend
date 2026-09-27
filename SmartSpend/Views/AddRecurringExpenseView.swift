import SwiftUI

struct AddRecurringExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared
    
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory: UserCategory?
    @State private var selectedRecurrence: RecurrenceType = .monthly
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var isActive = true
    @State private var showingCategoryManagement = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("expense_details".localized) {
                    TextField("title".localized, text: $title)
                        .textInputAutocapitalization(.words)

                    HStack {
                        Text("amount".localized)
                        Spacer()
                        Text(dataManager.user.currency.symbol)
                            .foregroundStyle(.secondary)
                        TextField("0", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 140)
                            .onChange(of: amount) { _, _ in formatAmountInput() }
                    }

                    RecurringCategoryPicker(selectedCategory: $selectedCategory) {
                        showingCategoryManagement = true
                    }
                }
                
                Section("recurrence".localized) {
                    Picker("frequency".localized, selection: $selectedRecurrence) {
                        ForEach(RecurrenceType.allCases, id: \.self) { recurrence in
                            HStack {
                                HeroIcon(systemName: recurrence.icon)
                                Text(recurrence.rawValue)
                            }
                            .tag(recurrence)
                        }
                    }
                    
                    DatePicker("start_date".localized, selection: $startDate, displayedComponents: .date)
                    
                    Toggle("end_date".localized, isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker("end_date".localized, selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }
                
                Section("settings".localized) {
                    Toggle("active".localized, isOn: $isActive)
                }
                
                Section {
                    RecurrencePreviewView(
                        recurrenceType: selectedRecurrence,
                        startDate: startDate,
                        endDate: hasEndDate ? endDate : nil
                    )
                }
            }
            .navigationTitle("add_recurring_expense".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("save".localized) {
                        saveRecurringExpense()
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingCategoryManagement) {
                CategoryManagementView()
            }
            .onAppear {
                if selectedCategory == nil {
                    selectedCategory = dataManager.userCategories.first
                }
            }
        }
    }
    
    private var canSave: Bool {
        guard let value = AmountInputFormatter.parse(amount), value > 0 else { return false }
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedCategory != nil
    }

    private func saveRecurringExpense() {
        guard let amountValue = AmountInputFormatter.parse(amount), let categoryId = selectedCategory?.id else { return }

        var newRecurring = RecurringExpense(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amountValue,
            categoryId: categoryId,
            recurrenceType: selectedRecurrence,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil
        )
        newRecurring.isActive = isActive

        dataManager.addRecurringExpense(newRecurring)
        dismiss()
    }

    private func formatAmountInput() {
        let formatted = AmountInputFormatter.formatEditingText(amount)
        if formatted != amount {
            amount = formatted
        }
    }
}

struct EditRecurringExpenseView: View {
    let recurringExpense: RecurringExpense
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared
    
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory: UserCategory?
    @State private var selectedRecurrence: RecurrenceType = .monthly
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var isActive = true
    @State private var showingCategoryManagement = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("expense_details".localized) {
                    TextField("title".localized, text: $title)
                        .textInputAutocapitalization(.words)

                    HStack {
                        Text("amount".localized)
                        Spacer()
                        Text(dataManager.user.currency.symbol)
                            .foregroundStyle(.secondary)
                        TextField("0", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 140)
                            .onChange(of: amount) { _, _ in formatAmountInput() }
                    }

                    RecurringCategoryPicker(selectedCategory: $selectedCategory) {
                        showingCategoryManagement = true
                    }
                }
                
                Section("recurrence".localized) {
                    Picker("frequency".localized, selection: $selectedRecurrence) {
                        ForEach(RecurrenceType.allCases, id: \.self) { recurrence in
                            HStack {
                                HeroIcon(systemName: recurrence.icon)
                                Text(recurrence.rawValue)
                            }
                            .tag(recurrence)
                        }
                    }
                    
                    DatePicker("start_date".localized, selection: $startDate, displayedComponents: .date)
                    
                    Toggle("end_date".localized, isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker("end_date".localized, selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }
                
                Section("settings".localized) {
                    Toggle("active".localized, isOn: $isActive)
                }
                
                Section("status".localized) {
                    if let lastProcessed = recurringExpense.lastProcessedDate {
                        HStack {
                            Text("last_processed".localized)
                            Spacer()
                            Text(DateFormatter.shortDate.string(from: lastProcessed))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("next_due".localized)
                        Spacer()
                        Text(DateFormatter.shortDate.string(from: recurringExpense.nextDueDate))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    RecurrencePreviewView(
                        recurrenceType: selectedRecurrence,
                        startDate: startDate,
                        endDate: hasEndDate ? endDate : nil
                    )
                }
            }
            .navigationTitle("edit_recurring_expense".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("save".localized) {
                        saveChanges()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                loadExpenseData()
            }
            .sheet(isPresented: $showingCategoryManagement) {
                CategoryManagementView()
            }
        }
    }
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !amount.isEmpty &&
        (AmountInputFormatter.parse(amount) ?? 0) > 0
    }
    
    private func loadExpenseData() {
        title = recurringExpense.title
        amount = AmountInputFormatter.formatValue(recurringExpense.amount)
        selectedCategory = DataManager.shared.resolveCategory(id: recurringExpense.categoryId)
        selectedRecurrence = recurringExpense.recurrenceType
        startDate = recurringExpense.startDate
        hasEndDate = recurringExpense.endDate != nil
        endDate = recurringExpense.endDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        isActive = recurringExpense.isActive
    }
    
    private func saveChanges() {
        guard let amountValue = AmountInputFormatter.parse(amount) else { return }
        
        var updatedExpense = recurringExpense
        updatedExpense.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedExpense.amount = amountValue
        updatedExpense.categoryId = selectedCategory?.id ?? recurringExpense.categoryId
        updatedExpense.recurrenceType = selectedRecurrence
        updatedExpense.startDate = startDate
        updatedExpense.endDate = hasEndDate ? endDate : nil
        updatedExpense.isActive = isActive
        
        dataManager.updateRecurringExpense(updatedExpense)
        dismiss()
    }

    private func formatAmountInput() {
        let formatted = AmountInputFormatter.formatEditingText(amount)
        if formatted != amount {
            amount = formatted
        }
    }
}

// MARK: - Shared Category Picker

struct RecurringCategoryPicker: View {
    @Binding var selectedCategory: UserCategory?
    var onCreateNew: () -> Void
    @ObservedObject private var dataManager = DataManager.shared

    var body: some View {
        HStack {
            Text("category".localized)
            Spacer()
            Menu {
                ForEach(dataManager.userCategories) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HeroIconLabel(title: category.name, systemName: category.iconSystemName)
                    }
                }
                Divider()
                Button(action: onCreateNew) {
                    HeroIconLabel(title: "create_new_category".localized, systemName: "plus.circle")
                }
            } label: {
                HStack(spacing: 6) {
                    if let category = selectedCategory {
                        HeroIcon(systemName: category.iconSystemName)
                            .foregroundStyle(category.color)
                        Text(category.name)
                            .foregroundStyle(.primary)
                    } else {
                        Text("select_category".localized)
                            .foregroundStyle(.secondary)
                    }
                    HeroIcon(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

// MARK: - Recurrence Preview
struct RecurrencePreviewView: View {
    let recurrenceType: RecurrenceType
    let startDate: Date
    let endDate: Date?
    
    private var upcomingDates: [Date] {
        var dates: [Date] = []
        var currentDate = startDate
        
        for _ in 0..<5 {
            dates.append(currentDate)
            currentDate = recurrenceType.nextDate(from: currentDate)
            
            if let end = endDate, currentDate > end {
                break
            }
        }
        
        return dates
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("upcoming_occurrences".localized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(upcomingDates.indices, id: \.self) { index in
                    HStack {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(DateFormatter.mediumDate.string(from: upcomingDates[index]))
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        if index == 0 {
                            Text("(\("start".localized))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                if upcomingDates.count == 5 {
                    Text("...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 20)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

#Preview {
    AddRecurringExpenseView()
}
