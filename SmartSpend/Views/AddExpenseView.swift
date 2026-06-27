import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared
    
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory: UserCategory?
    @State private var selectedDate = Date()
    @State private var showingSuggestions = false
    @State private var categorySuggestions: [(category: UserCategory, confidence: Double)] = []
    @State private var suggestedPrice: Double?
    @State private var showingCategoryManagement = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Title Field with Auto-completion
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("expense_title_placeholder".localized, text: $title, axis: .vertical)
                            .textFieldStyle(.plain)
                            .onChange(of: title) { _, _ in
                                checkForSuggestions()
                            }

                        if showingSuggestions && !categorySuggestions.isEmpty {
                            SmartSuggestionChips(
                                categories: categorySuggestions,
                                suggestedPrice: suggestedPrice,
                                currency: dataManager.user.currency,
                                onCategory: { category in
                                    selectedCategory = category
                                },
                                onPrice: { price in
                                    amount = AmountInputFormatter.formatValue(price)
                                }
                            )
                            .transition(.opacity)
                        }
                    }

                    // Amount Field
                    HStack {
                        Text(dataManager.user.currency.symbol)
                            .foregroundStyle(.secondary)
                            .font(.body)
                        TextField("0", text: $amount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .onChange(of: amount) {
                                formatAmountInput()
                            }
                    }
                    
                    // Category Selection
                    HStack {
                        Text("category".localized)
                        Spacer()
                        Menu {
                            ForEach(dataManager.userCategories) { userCategory in
                                Button(action: {
                                    selectedCategory = userCategory
                                }) {
                                    Label {
                                        Text(userCategory.name)
                                    } icon: {
                                        Image(systemName: userCategory.iconSystemName)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Create New Category
                            Button(action: { showingCategoryManagement = true }) {
                                Label("create_new_category".localized, systemImage: "plus.circle")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if let userCat = selectedCategory {
                                    Image(systemName: userCat.iconSystemName)
                                        .foregroundStyle(userCat.color)
                                    Text(userCat.name)
                                        .foregroundStyle(.primary)
                                } else {
                                    Text("select_category".localized)
                                        .foregroundStyle(.secondary)
                                }
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Date Picker
                    DatePicker("column_date".localized, selection: $selectedDate, displayedComponents: .date)
                } header: {
                    Text("expense_details".localized)
                }
            }
            .navigationTitle("add_expense".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                    .foregroundStyle(.tint)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("save".localized) {
                        saveExpense()
                    }
                    .disabled(title.isEmpty || amount.isEmpty || AmountInputFormatter.parse(amount) == nil || selectedCategory == nil)
                    .fontWeight(.semibold)
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
    
    private func checkForSuggestions() {
        guard !title.isEmpty else {
            showingSuggestions = false
            return
        }
        
        // Smart suggestions need a few expenses to learn from.
        guard dataManager.expenses.count >= 3 else {
            showingSuggestions = false
            return
        }
        
        // Get category predictions
        let categoryPreds = dataManager.getTopCategorySuggestions(for: title, limit: 3)
        
        // Get price suggestions from similar patterns
        let suggestions = dataManager.getCategoryFocusedSuggestions(for: title)
        let priceSuggestion = suggestions.first?.mostUsedPrice
        
        if !categoryPreds.isEmpty {
            categorySuggestions = categoryPreds
            suggestedPrice = priceSuggestion
            showingSuggestions = true
        } else {
            showingSuggestions = false
        }
    }
    
    private func saveExpense() {
        guard let amountValue = AmountInputFormatter.parse(amount),
              !title.isEmpty,
              let categoryId = selectedCategory?.id else { return }

        let expense = Expense(
            title: title,
            amount: amountValue,
            categoryId: categoryId,
            date: selectedDate
        )
        dataManager.addExpense(expense)
        dismiss()
    }
    
    private func formatAmountInput() {
        let formatted = AmountInputFormatter.formatEditingText(amount)
        if formatted != amount {
            amount = formatted
        }
    }
}

// MARK: - Compact smart suggestion chips

struct SmartSuggestionChips: View {
    let categories: [(category: UserCategory, confidence: Double)]
    let suggestedPrice: Double?
    let currency: Currency
    let onCategory: (UserCategory) -> Void
    let onPrice: (Double) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let price = suggestedPrice {
                    chip {
                        onPrice(price)
                    } content: {
                        Text(CurrencyFormatter.format(price, currency: currency))
                    }
                }

                ForEach(categories, id: \.category) { item in
                    chip {
                        onCategory(item.category)
                    } content: {
                        HStack(spacing: 4) {
                            Image(systemName: item.category.iconSystemName)
                                .foregroundStyle(item.category.color)
                            Text(item.category.name)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip<Content: View>(action: @escaping () -> Void,
                                     @ViewBuilder content: () -> Content) -> some View {
        Button(action: action) {
            content()
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(.systemGray6), in: Capsule())
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddExpenseView()
}
