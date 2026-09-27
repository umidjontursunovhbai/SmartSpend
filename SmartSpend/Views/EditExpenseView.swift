import SwiftUI

struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared
    
    let expense: Expense
    
    @State private var title: String
    @State private var amount: String
    @State private var selectedCategory: UserCategory?
    @State private var selectedDate: Date
    @State private var showingCategoryManagement = false
    
    
    init(expense: Expense) {
        self.expense = expense
        self._title = State(initialValue: expense.title)
        self._amount = State(initialValue: AmountInputFormatter.formatValue(expense.amount))
        self._selectedCategory = State(initialValue: DataManager.shared.resolveCategory(id: expense.categoryId))
        self._selectedDate = State(initialValue: expense.date)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Title Field
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Expense title", text: $title, axis: .vertical)
                            .textFieldStyle(.plain)
                    }
                    
                    // Amount Field
                    HStack {
                        Text(dataManager.user.currency.symbol)
                            .foregroundStyle(.secondary)
                            .font(.body)
                        TextField("0", text: $amount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .onChange(of: amount) { _, _ in
                                formatAmountInput()
                            }
                    }
                    
                    // Category Selection - Focus on User Categories
                    HStack {
                        Text("Category")
                        Spacer()
                        Menu {
                            // User Custom Categories
                            ForEach(dataManager.userCategories) { userCategory in
                                Button(action: {
                                    selectedCategory = userCategory
                                }) {
                                    Label {
                                        Text(userCategory.name)
                                    } icon: {
                                        HeroIcon(systemName: userCategory.iconSystemName)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Create New Category
                            Button(action: { showingCategoryManagement = true }) {
                                HeroIconLabel(title: "Create New Category", systemName: "plus.circle")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if let userCat = selectedCategory {
                                    HeroIcon(systemName: userCat.iconSystemName)
                                        .foregroundStyle(userCat.color)
                                    Text(userCat.name)
                                        .foregroundStyle(.primary)
                                } else {
                                    Text("Select Category")
                                        .foregroundStyle(.secondary)
                                }
                                HeroIcon(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Date Picker
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                } header: {
                    Text("Expense Details")
                } footer: {
                    Text("Update your expense details.")
                        .font(.caption)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.tint)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        updateExpense()
                    }
                    .disabled(title.isEmpty || amount.isEmpty || AmountInputFormatter.parse(amount) == nil)
                    .fontWeight(.semibold)
                    .foregroundStyle(title.isEmpty || amount.isEmpty || AmountInputFormatter.parse(amount) == nil ? Color.secondary : Color.accentColor)
                }
            }
            .sheet(isPresented: $showingCategoryManagement) {
                CategoryManagementView()
            }
        }
    }
    
    private func updateExpense() {
        guard let amountValue = AmountInputFormatter.parse(amount), !title.isEmpty else { return }
        
        // Find and update the expense - PRESERVE THE ORIGINAL ID
        if let index = dataManager.expenses.firstIndex(where: { $0.id == expense.id }) {
            var updatedExpense = dataManager.expenses[index]
            updatedExpense.title = title
            updatedExpense.amount = amountValue
            updatedExpense.categoryId = selectedCategory?.id ?? expense.categoryId
            updatedExpense.date = selectedDate
            
            dataManager.expenses[index] = updatedExpense
        }
        
        dismiss()
    }

    private func formatAmountInput() {
        let formatted = AmountInputFormatter.formatEditingText(amount)
        if formatted != amount {
            amount = formatted
        }
    }
}

#Preview {
    EditExpenseView(expense: Expense(
        title: "Coffee",
        amount: 4.50,
        categoryId: UUID(),
        date: Date()
    ))
}
