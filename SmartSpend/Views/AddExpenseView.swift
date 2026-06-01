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
    @State private var showingScanner = false
    
    // Recurring expense options
    @State private var isRecurring = false
    @State private var selectedRecurrence: RecurrenceType = .monthly
    @State private var hasEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Title Field with Auto-completion
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("expense_title_placeholder".localized, text: $title, axis: .vertical)
                            .textFieldStyle(.plain)
                            .onChange(of: title) { _, _ in
                                checkForSuggestions()
                            }
                        
                        if showingSuggestions && !categorySuggestions.isEmpty {
                            EnhancedSuggestionView(
                                categorySuggestions: categorySuggestions,
                                suggestedPrice: suggestedPrice,
                                currency: dataManager.user.currency,
                                onCategorySelect: { category in
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        self.selectedCategory = category
                                        // Don't dismiss suggestions - let user also select price if they want
                                    }
                                },
                                onPriceSelect: { price in
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        self.amount = formatNumberWithCommas(price)
                                        // Don't dismiss suggestions - let user also select category if they want
                                    }
                                },
                                onDismiss: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        self.showingSuggestions = false
                                    }
                                }
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
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
                                    Text("Select Category")
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
                } footer: {
                    Text("smart_suggestions_footer".localized)
                        .font(.caption)
                }
                
                // Recurring Section
                Section {
                    Toggle(isOn: $isRecurring.animation()) {
                        Label("make_recurring".localized, systemImage: "repeat")
                    }
                    
                    if isRecurring {
                        Picker("frequency".localized, selection: $selectedRecurrence) {
                            ForEach(RecurrenceType.allCases, id: \.self) { recurrence in
                                HStack {
                                    Image(systemName: recurrence.icon)
                                    Text(recurrence.rawValue)
                                }
                                .tag(recurrence)
                            }
                        }
                        
                        Toggle("set_end_date".localized, isOn: $hasEndDate.animation())
                        
                        if hasEndDate {
                            DatePicker("end_date".localized, selection: $endDate, in: selectedDate..., displayedComponents: .date)
                        }
                    }
                } header: {
                    Text("recurring".localized)
                } footer: {
                    if isRecurring {
                        Text(String(format: "recurring_footer_format".localized, selectedRecurrence.rawValue.lowercased()))
                            .font(.caption)
                    }
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
                    HStack(spacing: 16) {
                        Button(action: { showingScanner = true }) {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.headline)
                        }
                        
                        Button("save".localized) {
                            saveExpense()
                        }
                        .disabled(title.isEmpty || amount.isEmpty || getNumericValue(from: amount) == nil || selectedCategory == nil)
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                ScannerView { result in
                    if let amountValue = result.amount {
                        self.amount = formatNumberWithCommas(amountValue)
                    }
                    if let dateValue = result.date {
                        self.selectedDate = dateValue
                    }
                    checkForSuggestions()
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
        
        // Check if smart suggestions are enabled (need at least 3 expenses to start learning)
        guard dataManager.expenses.count >= 3 else {
            print("🔍 Smart Learning: Not enough expenses (\(dataManager.expenses.count)/3)")
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
        guard let amountValue = getNumericValue(from: amount), !title.isEmpty else { return }
        
        // Create and save the regular expense
        let expense = Expense(
            title: title,
            amount: amountValue,
            categoryId: selectedCategory?.id ?? DataManager.shared.resolveCategory(id: UUID()).id, // Fallback safe
            date: selectedDate
        )
        
        dataManager.addExpense(expense)
        
        // If recurring is enabled, also create a recurring expense
        if isRecurring {
            let recurringExpense = RecurringExpense(
                title: title,
                amount: amountValue,
                categoryId: selectedCategory?.id ?? DataManager.shared.resolveCategory(id: UUID()).id,
                recurrenceType: selectedRecurrence,
                startDate: selectedDate,
                endDate: hasEndDate ? endDate : nil
            )
            dataManager.addRecurringExpense(recurringExpense)
        }
        
        dismiss()
    }
    
    private func formatAmountInput() {
        // Remove all non-numeric characters except decimal point
        let cleanedInput = amount.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        
        // Convert to number and format with commas
        if let number = Double(cleanedInput) {
            let formatted = formatNumberWithCommas(number)
            if formatted != amount {
                amount = formatted
            }
        }
    }
    
    private static let commaFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return f
    }()

    private func formatNumberWithCommas(_ number: Double) -> String {
        return Self.commaFormatter.string(from: NSNumber(value: number)) ?? ""
    }
    
    private func getNumericValue(from text: String) -> Double? {
        // Remove commas and convert to double
        let cleanedText = text.replacingOccurrences(of: ",", with: "")
        return Double(cleanedText)
    }
}

struct EnhancedSuggestionView: View {
    let categorySuggestions: [(category: UserCategory, confidence: Double)]
    let suggestedPrice: Double?
    let currency: Currency
    let onCategorySelect: (UserCategory) -> Void
    let onPriceSelect: (Double) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedCategory: UserCategory?
    @State private var selectedPrice: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            suggestionHeader
            
            // Category Suggestions
            categorySection
            
            // Price Suggestion
            if let price = suggestedPrice {
                Divider()
                priceSection(price: price)
            }
            
            // Helper text
            if selectedCategory != nil || selectedPrice != nil {
                Divider()
                helperText
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemBlue).opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - View Components
    
    private var suggestionHeader: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(Color(.systemBlue))
                .font(.caption)
            Text("Smart Suggestions")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Likely Categories:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            ForEach(categorySuggestions, id: \.category) { suggestion in
                categoryButton(for: suggestion)
            }
        }
    }
    
    private func categoryButton(for suggestion: (category: UserCategory, confidence: Double)) -> some View {
        let isSelected = selectedCategory == suggestion.category
        
        return Button {
            selectedCategory = suggestion.category
            onCategorySelect(suggestion.category)
        } label: {
            HStack {
                Label(suggestion.category.name, systemImage: suggestion.category.iconSystemName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : suggestion.category.color)
                
                Spacer()
                
                Text("\(Int(suggestion.confidence * 100))%")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isSelected ? suggestion.category.color : Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? suggestion.category.color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func priceSection(price: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested Price:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            priceButton(price: price)
        }
    }
    
    private func priceButton(price: Double) -> some View {
        let isSelected = selectedPrice == price
        
        return Button {
            selectedPrice = price
            onPriceSelect(price)
        } label: {
            HStack {
                Text(formatCurrency(price, currency))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : .primary)
                
                Spacer()
                
                Text(isSelected ? "Selected" : "Use Price")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        isSelected ? .green : .blue,
                        in: RoundedRectangle(cornerRadius: 6)
                    )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isSelected ? .green.opacity(0.2) : Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? .green : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var helperText: some View {
        Text("💡 You can select both price and category, or tap X to close")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
    
    private func formatCurrency(_ amount: Double, _ currency: Currency) -> String {
        return CurrencyFormatter.format(amount, currency: currency)
    }
}

struct SuggestionView: View {
    let price: Double
    let category: UserCategory
    let currency: Currency
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color(.systemBlue))
                    .font(.caption)
                Text("Smart Suggestion")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatCurrency(price, currency))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Label(category.name, systemImage: category.iconSystemName)
                        .font(.caption)
                        .foregroundStyle(category.color)
                }
                
                Spacer()
                
                Button(action: {
                    onAccept()
                }) {
                    Text("Use")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemBlue).opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatCurrency(_ amount: Double, _ currency: Currency) -> String {
        return CurrencyFormatter.format(amount, currency: currency)
    }
}

#Preview {
    AddExpenseView()
}
