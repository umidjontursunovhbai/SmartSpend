import Foundation
import SwiftUI
import WidgetKit

enum TimePeriod: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case currentMonth = "This Month"
    case lastMonth = "Last Month"
    case all = "All Time"
    case customMonth = "Custom Month"
    
    var icon: String {
        switch self {
        case .today: return "calendar.day.timeline.left"
        case .thisWeek: return "calendar.badge.clock"
        case .currentMonth: return "calendar"
        case .lastMonth: return "calendar.badge.clock"
        case .all: return "infinity"
        case .customMonth: return "calendar.badge.exclamationmark"
        }
    }
    
    var localizedName: String {
        switch self {
        case .today: return "time_period_today".localized
        case .thisWeek: return "time_period_this_week".localized
        case .currentMonth: return "time_period_this_month".localized
        case .lastMonth: return "time_period_last_month".localized
        case .all: return "time_period_all".localized
        case .customMonth: return "time_period_custom".localized
        }
    }
}

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var expenses: [Expense] = []
    @Published var user: User
    @Published var deletedExpenses: [ArchivedExpense] = []
    @Published var categoryBudgets: [CategoryBudget] = []
    @Published var spendingGoals: [SpendingGoal] = []
    @Published var monthlySalaries: [MonthlySalary] = []
    @Published var recurringExpenses: [RecurringExpense] = []
    @Published var learnedPatterns: [LearnedPattern] = []
    @Published var userCategories: [UserCategory] = []
    @Published var selectedTimePeriod: TimePeriod = .currentMonth
    @Published var customStartDate: Date = Date()
    @Published var customEndDate: Date = Date()

    private let sharedDefaults = UserDefaults(suiteName: "group.com.tursunov.SmartSpend") ?? UserDefaults.standard

    private init() {
        self.user = User(currency: .usd, language: .english)
        loadData()
        startTimer()
    }
    
    // MARK: - Data Persistence
    
    private func saveData() {
        do {
            let encoder = JSONEncoder()
            
            // Save to local UserDefaults
            let expensesData = try encoder.encode(expenses)
            sharedDefaults.set(expensesData, forKey: "expenses")
            
            let userData = try encoder.encode(user)
            sharedDefaults.set(userData, forKey: "user")
            
            let deletedExpensesData = try encoder.encode(deletedExpenses)
            sharedDefaults.set(deletedExpensesData, forKey: "archivedExpenses")
            
            let categoryBudgetsData = try encoder.encode(categoryBudgets)
            sharedDefaults.set(categoryBudgetsData, forKey: "categoryBudgets")
            
            let spendingGoalsData = try encoder.encode(spendingGoals)
            sharedDefaults.set(spendingGoalsData, forKey: "spendingGoals")
            
            let monthlySalariesData = try encoder.encode(monthlySalaries)
            sharedDefaults.set(monthlySalariesData, forKey: "monthlySalaries")
            
            let recurringExpensesData = try encoder.encode(recurringExpenses)
            sharedDefaults.set(recurringExpensesData, forKey: "recurringExpenses")
            
            let learnedPatternsData = try encoder.encode(learnedPatterns)
            sharedDefaults.set(learnedPatternsData, forKey: "learnedPatterns")
            
            let userCategoriesData = try encoder.encode(userCategories)
            sharedDefaults.set(userCategoriesData, forKey: "userCategories")
            
            // Save custom date range
            sharedDefaults.set(customStartDate, forKey: "customStartDate")
            sharedDefaults.set(customEndDate, forKey: "customEndDate")
            
        } catch {
            print("Error saving data: \(error)")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func loadData() {
        let decoder = JSONDecoder()
        
        if let expensesData = sharedDefaults.data(forKey: "expenses"),
           let decodedExpenses = try? decoder.decode([Expense].self, from: expensesData) {
            self.expenses = decodedExpenses
        }
        
        if let userData = sharedDefaults.data(forKey: "user"),
           let decodedUser = try? decoder.decode(User.self, from: userData) {
            self.user = decodedUser
        }
        
        if let deletedExpensesData = sharedDefaults.data(forKey: "archivedExpenses"),
           let decodedDeletedExpenses = try? decoder.decode([ArchivedExpense].self, from: deletedExpensesData) {
            self.deletedExpenses = decodedDeletedExpenses
        }
        
        if let categoryBudgetsData = sharedDefaults.data(forKey: "categoryBudgets"),
           let decodedCategoryBudgets = try? decoder.decode([CategoryBudget].self, from: categoryBudgetsData) {
            self.categoryBudgets = decodedCategoryBudgets
        }
        
        if let spendingGoalsData = sharedDefaults.data(forKey: "spendingGoals"),
           let decodedSpendingGoals = try? decoder.decode([SpendingGoal].self, from: spendingGoalsData) {
            self.spendingGoals = decodedSpendingGoals
        }
        
        if let monthlySalariesData = sharedDefaults.data(forKey: "monthlySalaries"),
           let decodedMonthlySalaries = try? decoder.decode([MonthlySalary].self, from: monthlySalariesData) {
            self.monthlySalaries = decodedMonthlySalaries
        }
        
        if let recurringExpensesData = sharedDefaults.data(forKey: "recurringExpenses"),
           let decodedRecurringExpenses = try? decoder.decode([RecurringExpense].self, from: recurringExpensesData) {
            self.recurringExpenses = decodedRecurringExpenses
        }
        
        if let learnedPatternsData = sharedDefaults.data(forKey: "learnedPatterns"),
           let decodedLearnedPatterns = try? decoder.decode([LearnedPattern].self, from: learnedPatternsData) {
            self.learnedPatterns = decodedLearnedPatterns
        }
        
        if let userCategoriesData = sharedDefaults.data(forKey: "userCategories"),
           let decodedUserCategories = try? decoder.decode([UserCategory].self, from: userCategoriesData) {
            self.userCategories = decodedUserCategories
        }
        
        // No longer auto-creating default categories.
        // Categories must be explicitly created by the user or imported.
        
        // Load custom date range
        if let savedStartDate = sharedDefaults.object(forKey: "customStartDate") as? Date {
            self.customStartDate = savedStartDate
        }
        if let savedEndDate = sharedDefaults.object(forKey: "customEndDate") as? Date {
            self.customEndDate = savedEndDate
        }
        
        // Rebuild patterns from recent expenses on app launch
        rebuildLearnedPatternsFromRecentExpenses()
    }
    
    // MARK: - Expense Management
    
    func addExpense(_ expense: Expense) {
        // Ensure this runs on main thread to avoid SwiftUI threading issues
        if Thread.isMainThread {
            addExpenseInternal(expense)
        } else {
            DispatchQueue.main.async {
                self.addExpenseInternal(expense)
            }
        }
    }

    func addExpensesBatch(_ newExpenses: [Expense]) {
        expenses.append(contentsOf: newExpenses)
        saveData()
        rebuildLearnedPatternsFromRecentExpenses()
    }

    private func addExpenseInternal(_ expense: Expense) {
        expenses.append(expense)
        saveData()
        updateLearnedPatterns(for: expense)
        // Gamification tracking
        gamificationManager.recordExpense()
    }
    
    func updateExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            saveData()
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        saveData()
    }
    
    func moveToDeletedExpenses(_ expense: Expense) {
        let deletedExpense = ArchivedExpense(from: expense)
        deletedExpenses.append(deletedExpense)
        expenses.removeAll { $0.id == expense.id }
        saveData()
    }
    
    func restoreExpense(_ deletedExpense: ArchivedExpense) {
        let expense = Expense(
            title: deletedExpense.title,
            amount: deletedExpense.amount,
            categoryId: deletedExpense.categoryId,
            date: deletedExpense.date
        )
        expenses.append(expense)
        deletedExpenses.removeAll { $0.id == deletedExpense.id }
        saveData()
    }
    
    func permanentlyDeleteExpense(_ deletedExpense: ArchivedExpense) {
        deletedExpenses.removeAll { $0.id == deletedExpense.id }
        saveData()
    }
    
    // MARK: - Today's Expenses
    
    func getTodaysExpenses() -> [Expense] {
        let calendar = Calendar.current
        let today = Date()
        return expenses.filter { calendar.isDate($0.date, equalTo: today, toGranularity: .day) }
            .sorted { $0.date > $1.date }
    }
    
    func getTodaysExpensesTotal() -> Double {
        let todaysExpenses = getTodaysExpenses()
        return todaysExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Other Methods (keeping existing functionality)
    
    func getTotalExpenses() -> Double {
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    func getCurrentMonthSalary() -> Double {
        let calendar = Calendar.current
        let currentDate = Date()
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        return getSalaryForMonth(month: currentMonth, year: currentYear)
    }
    
    func getSalaryForMonth(month: Int, year: Int) -> Double {
        if let salary = monthlySalaries.first(where: { $0.month == month && $0.year == year }) {
            return salary.amount
        }
        return 0.0
    }
    
    func getRemainingBudget() -> Double {
        let currentSalary = getCurrentMonthSalary()
        let totalExpenses = getTotalExpenses()
        return currentSalary - totalExpenses
    }
    
    func getExpensesByCategory() -> [UserCategory: Double] {
        var categoryTotals: [UserCategory: Double] = [:]
        
        for expense in expenses {
            let category = resolveCategory(id: expense.categoryId)
            if let existingTotal = categoryTotals[category] {
                categoryTotals[category] = existingTotal + expense.amount
            } else {
                categoryTotals[category] = expense.amount
            }
        }
        
        return categoryTotals
    }
    
    func updateUser(_ newUser: User) {
        self.user = newUser
        saveData()
    }
    
    func addCategoryBudget(_ budget: CategoryBudget) {
        categoryBudgets.append(budget)
        saveData()
    }
    
    func updateCategoryBudget(_ budget: CategoryBudget) {
        if let index = categoryBudgets.firstIndex(where: { $0.id == budget.id }) {
            categoryBudgets[index] = budget
            saveData()
        }
    }
    
    func deleteCategoryBudget(_ budget: CategoryBudget) {
        categoryBudgets.removeAll { $0.id == budget.id }
        saveData()
    }
    
    func addSpendingGoal(_ goal: SpendingGoal) {
        spendingGoals.append(goal)
        saveData()
    }
    
    func updateSpendingGoal(_ goal: SpendingGoal) {
        if let index = spendingGoals.firstIndex(where: { $0.id == goal.id }) {
            spendingGoals[index] = goal
            saveData()
        }
    }
    
    func deleteSpendingGoal(_ goal: SpendingGoal) {
        spendingGoals.removeAll { $0.id == goal.id }
        saveData()
    }
    
    func addMonthlySalary(_ salary: MonthlySalary) {
        if let existingIndex = monthlySalaries.firstIndex(where: { $0.month == salary.month && $0.year == salary.year }) {
            monthlySalaries[existingIndex] = salary
        } else {
            monthlySalaries.append(salary)
        }
        saveData()
    }
    
    func setSalaryForMonth(year: Int, month: Int, amount: Double) {
        // Remove existing salary for this month if it exists
        monthlySalaries.removeAll { $0.year == year && $0.month == month }
        
        // Add new salary
        let newSalary = MonthlySalary(year: year, month: month, amount: amount, currency: user.currency)
        monthlySalaries.append(newSalary)
        
        saveData()
    }
    
    func deleteMonthlySalary(_ salary: MonthlySalary) {
        monthlySalaries.removeAll { $0.id == salary.id }
        saveData()
    }
    
    func addRecurringExpense(_ expense: RecurringExpense) {
        recurringExpenses.append(expense)
        saveData()
    }
    
    func updateRecurringExpense(_ expense: RecurringExpense) {
        if let index = recurringExpenses.firstIndex(where: { $0.id == expense.id }) {
            recurringExpenses[index] = expense
            saveData()
        }
    }
    
    func deleteRecurringExpense(_ expense: RecurringExpense) {
        recurringExpenses.removeAll { $0.id == expense.id }
        saveData()
    }
    
    func updateLearnedPatterns(for expense: Expense) {
        // Only rebuild patterns periodically for performance
        // Check if we should rebuild (every 10 expenses or if patterns are empty)
        let shouldRebuild = learnedPatterns.isEmpty || expenses.count % 10 == 0
        
        if shouldRebuild {
            rebuildLearnedPatternsFromRecentExpenses()
        } else {
            // Quick update: just add to existing pattern or create new one
            quickUpdatePattern(for: expense)
        }
        
        saveData()
    }
    
    private func quickUpdatePattern(for expense: Expense) {
        // Check if expense is from last 3 months
        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        
        guard expense.date >= threeMonthsAgo else {
            return // Don't add patterns for old expenses
        }
        
        // Try to find existing pattern
        if let existingIndex = learnedPatterns.firstIndex(where: { 
            $0.title.lowercased() == expense.title.lowercased()
        }) {
            // Update existing pattern
            learnedPatterns[existingIndex].addCombination(price: expense.amount, categoryId: expense.categoryId)
        } else {
            // Check for similar patterns
            let similarPatterns = learnedPatterns
                .map { pattern in
                    (pattern: pattern, similarity: pattern.similarityScore(with: expense.title))
                }
                .filter { $0.similarity > 0.7 }
                .sorted { $0.similarity > $1.similarity }
            
            if let bestMatch = similarPatterns.first {
                // Update the most similar pattern
                if let index = learnedPatterns.firstIndex(where: { $0.id == bestMatch.pattern.id }) {
                    learnedPatterns[index].addCombination(price: expense.amount, categoryId: expense.categoryId)
                }
            } else {
                // Create new pattern
                let pattern = LearnedPattern(
                    title: expense.title,
                    price: expense.amount,
                    categoryId: expense.categoryId
                )
                learnedPatterns.append(pattern)
            }
        }
    }
    
    // Method to manually refresh patterns (can be called from settings)
    func refreshSmartLearningPatterns() {
        rebuildLearnedPatternsFromRecentExpenses()
        saveData()
    }
    
    private func rebuildLearnedPatternsFromRecentExpenses() {
        // Get expenses from last 3 months
        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        
        let recentExpenses = expenses.filter { expense in
            expense.date >= threeMonthsAgo
        }
        
        // Clear existing patterns and rebuild from recent expenses
        learnedPatterns.removeAll()
        
        // Group expenses by title (case-insensitive) and build patterns
        var expenseGroups: [String: [Expense]] = [:]
        
        for expense in recentExpenses {
            let normalizedTitle = expense.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            expenseGroups[normalizedTitle, default: []].append(expense)
        }
        
        // Create patterns from grouped expenses
        for (_, expensesForTitle) in expenseGroups {
            guard !expensesForTitle.isEmpty else { continue }
            
            // Use the original case from the most recent expense
            let mostRecentExpense = expensesForTitle.max(by: { $0.date < $1.date }) ?? expensesForTitle.first!
            
            // Create new pattern with the first expense
            var pattern = LearnedPattern(
                title: mostRecentExpense.title,
                price: mostRecentExpense.amount,
                categoryId: mostRecentExpense.categoryId
            )
            
            // Add all other expenses to the pattern
            for expense in expensesForTitle.dropFirst() {
                pattern.addCombination(price: expense.amount, categoryId: expense.categoryId)
            }
            
            learnedPatterns.append(pattern)
        }
        
        // Also check for similar patterns that should be merged
        mergeSimilarPatterns()
    }
    
    private func mergeSimilarPatterns() {
        var indicesToRemove: Set<Int> = []
        
        for i in 0..<learnedPatterns.count {
            guard !indicesToRemove.contains(i) else { continue }
            
            for j in (i+1)..<learnedPatterns.count {
                guard !indicesToRemove.contains(j) else { continue }
                
                let similarity = learnedPatterns[i].similarityScore(with: learnedPatterns[j].title)
                
                // Merge patterns with high similarity (>0.8)
                if similarity > 0.8 {
                    // Merge pattern j into pattern i
                    for categoryFreq in learnedPatterns[j].categoryFrequencies {
                        for _ in 0..<categoryFreq.frequency {
                            learnedPatterns[i].addCombination(price: 0, categoryId: categoryFreq.categoryId)
                        }
                    }
                    
                    // Mark pattern j for removal
                    indicesToRemove.insert(j)
                }
            }
        }
        
        // Remove merged patterns (in reverse order to maintain indices)
        for index in indicesToRemove.sorted(by: >) {
            learnedPatterns.remove(at: index)
        }
    }
    
    func getSmartSuggestions(for title: String) -> [LearnedPattern] {
        // Filter patterns by similarity score
        let similarPatterns = learnedPatterns
            .map { pattern in
                (pattern: pattern, similarity: pattern.similarityScore(with: title))
            }
            .filter { $0.similarity > 0.1 } // Lower threshold for more sensitive matching
            .sorted { $0.similarity > $1.similarity }
            .prefix(5)
            .map { $0.pattern }
        
        // If no similar patterns found, fall back to old method
        if similarPatterns.isEmpty {
            return learnedPatterns
                .filter { $0.title.lowercased().contains(title.lowercased()) || title.lowercased().contains($0.title.lowercased()) }
                .sorted { $0.totalFrequency > $1.totalFrequency }
                .prefix(3)
                .map { $0 }
        }
        
        return Array(similarPatterns)
    }
    
    // New method: Get category prediction for a title
    func getCategoryPrediction(for title: String) -> (category: UserCategory, confidence: Double)? {
        let suggestions = getSmartSuggestions(for: title)
        
        guard !suggestions.isEmpty else { return nil }
        
        // Calculate weighted category prediction
        var categoryScores: [UUID: Double] = [:]
        
        for suggestion in suggestions {
            let similarity = suggestion.similarityScore(with: title)
            let confidence = suggestion.categoryConfidence
            
            // Weight by similarity and confidence
            let weight = similarity * confidence
            
            for categoryFreq in suggestion.categoryFrequencies {
                let score = Double(categoryFreq.frequency) * weight
                categoryScores[categoryFreq.categoryId, default: 0.0] += score
            }
        }
        
        // Find the category with highest score
        guard let bestCategoryId = categoryScores.max(by: { $0.value < $1.value })?.key else {
            return nil
        }
        
        // Calculate overall confidence
        let totalScore = categoryScores.values.reduce(0, +)
        let confidence = totalScore > 0 ? categoryScores[bestCategoryId]! / totalScore : 0.0
        
        let category = resolveCategory(id: bestCategoryId)
        return (category: category, confidence: min(confidence, 1.0))
    }
    
    // New method: Get top category suggestions for a title
    func getTopCategorySuggestions(for title: String, limit: Int = 3) -> [(category: UserCategory, confidence: Double)] {
        let suggestions = getSmartSuggestions(for: title)
        
        guard !suggestions.isEmpty else { return [] }
        
        // Calculate weighted category scores
        var categoryScores: [UUID: Double] = [:]
        
        for suggestion in suggestions {
            let similarity = suggestion.similarityScore(with: title)
            let confidence = suggestion.categoryConfidence
            
            let weight = similarity * confidence
            
            for categoryFreq in suggestion.categoryFrequencies {
                let score = Double(categoryFreq.frequency) * weight
                categoryScores[categoryFreq.categoryId, default: 0.0] += score
            }
        }
        
        // Sort by score and return top categories
        let totalScore = categoryScores.values.reduce(0, +)
        
        return categoryScores
            .map { (id, score) -> (category: UserCategory, confidence: Double) in
                let confidence = totalScore > 0 ? score / totalScore : 0.0
                return (category: resolveCategory(id: id), confidence: min(confidence, 1.0))
            }
            .sorted { $0.confidence > $1.confidence }
            .prefix(limit)
            .map { (category: $0.category, confidence: $0.confidence) }
    }
    
    // Enhanced method: Get smart suggestions with category focus
    func getCategoryFocusedSuggestions(for title: String) -> [LearnedPattern] {
        let suggestions = getSmartSuggestions(for: title)
        
        // Sort by category confidence and similarity
        return suggestions.sorted { pattern1, pattern2 in
            let similarity1 = pattern1.similarityScore(with: title)
            let similarity2 = pattern2.similarityScore(with: title)
            
            let score1 = similarity1 * pattern1.categoryConfidence
            let score2 = similarity2 * pattern2.categoryConfidence
            
            if abs(score1 - score2) < 0.1 {
                // If scores are close, prefer more recent patterns
                return pattern1.lastUsed > pattern2.lastUsed
            }
            
            return score1 > score2
        }
    }
    
    func clearAllData() {
        expenses.removeAll()
        user = User(currency: .usd)
        deletedExpenses.removeAll()
        categoryBudgets.removeAll()
        spendingGoals.removeAll()
        monthlySalaries.removeAll()
        recurringExpenses.removeAll()
        learnedPatterns.removeAll()
        userCategories.removeAll()
        saveData()
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.cleanupExpiredDeletedExpenses()
            self.processRecurringExpenses()
        }
    }
    
    private func cleanupExpiredDeletedExpenses() {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        deletedExpenses.removeAll { deletedExpense in
            calendar.isDate(deletedExpense.archivedDate, inSameDayAs: thirtyDaysAgo) ||
            deletedExpense.archivedDate < thirtyDaysAgo
        }
        saveData()
    }
    
    func processRecurringExpenses() {
        let calendar = Calendar.current
        let today = Date()
        
        for recurringExpense in recurringExpenses {
            if let lastProcessed = recurringExpense.lastProcessedDate,
               calendar.isDate(lastProcessed, inSameDayAs: today) {
                continue
            }
            
            if recurringExpense.shouldCreateExpense(on: today) {
                let newExpense = Expense(
                    title: recurringExpense.title,
                    amount: recurringExpense.amount,
                    categoryId: recurringExpense.categoryId,
                    date: today
                )
                
                addExpense(newExpense)
                
                // Update last processed date
                if let index = recurringExpenses.firstIndex(where: { $0.id == recurringExpense.id }) {
                    recurringExpenses[index].lastProcessedDate = today
                    saveData()
                }
            }
        }
    }
    
    // MARK: - Manager Access
    
    var deleteButtonManager: DeleteButtonManager {
        return DeleteButtonManager.shared
    }
    
    var tabManager: TabManager {
        return TabManager.shared
    }
    
    var gamificationManager: GamificationManager {
        return GamificationManager.shared
    }
    
    // MARK: - Deleted Expenses Helper
    
    func getDaysRemainingForExpense(_ deletedExpense: ArchivedExpense) -> Int {
        let calendar = Calendar.current
        let thirtyDaysAfterArchiving = calendar.date(byAdding: .day, value: 30, to: deletedExpense.archivedDate) ?? Date()
        let today = Date()
        
        let daysRemaining = calendar.dateComponents([.day], from: today, to: thirtyDaysAfterArchiving).day ?? 0
        return max(0, daysRemaining)
    }
    
    func checkBudgetAlerts() -> [String] {
        var alerts: [String] = []
        
        for budget in categoryBudgets {
            let categoryExpenses = expenses.filter { $0.categoryId == budget.categoryId }
            let totalSpent = categoryExpenses.reduce(0) { $0 + $1.amount }
            
            let category = resolveCategory(id: budget.categoryId)
            
            if totalSpent > budget.amount {
                let overspent = totalSpent - budget.amount
                alerts.append("Over budget for \(category.name) by \(CurrencyFormatter.format(overspent, currency: user.currency))")
            } else if totalSpent > budget.amount * 0.8 {
                let remaining = budget.amount - totalSpent
                alerts.append("Close to budget limit for \(category.name). \(CurrencyFormatter.format(remaining, currency: user.currency)) remaining")
            }
        }
        
        return alerts
    }
    
    func updateSpendingGoalProgress() {
        // Update progress for all spending goals based on current expenses
        for index in spendingGoals.indices {
            let goal = spendingGoals[index]
            let categoryExpenses = expenses.filter { $0.categoryId == goal.categoryId }
            let totalSpent = categoryExpenses.reduce(0) { $0 + $1.amount }
            
            // Calculate progress as percentage
            _ = min(totalSpent / goal.targetAmount, 1.0)
            spendingGoals[index].currentAmount = totalSpent
            
            // Update the progress in the goal if it has a progress property
            // Since SpendingGoal might not have a progress property, we'll just update currentAmount
        }
        saveData()
    }
    
    func getRecurringExpenseNotifications() -> [RecurringExpenseNotification] {
        var notifications: [RecurringExpenseNotification] = []
        
        for recurringExpense in recurringExpenses {
            if recurringExpense.shouldCreateExpense(on: Date()) {
                let notification = RecurringExpenseNotification(
                    recurringExpense: recurringExpense,
                    type: .due
                )
                notifications.append(notification)
            }
        }
        
        return notifications
    }
    
    func saveBudgets() {
        saveData()
    }
    
    func saveSpendingGoals() {
        saveData()
    }
    
    func updateCurrency(_ currency: Currency) {
        user.currency = currency
        saveData()
    }
    
    func updateLanguage(_ language: Language) {
        user.language = language
        saveData()
    }
    
    // MARK: - User Categories
    func addUserCategory(_ category: UserCategory) {
        // Prevent duplicates by name (case-insensitive)
        if !userCategories.contains(where: { $0.name.lowercased() == category.name.lowercased() }) {
            userCategories.append(category)
            saveData()
        }
    }
    
    func updateUserCategory(_ category: UserCategory) {
        if let index = userCategories.firstIndex(where: { $0.id == category.id }) {
            userCategories[index] = category
            saveData()
        }
    }
    
    func deleteUserCategory(_ category: UserCategory) {
        userCategories.removeAll { $0.id == category.id }
        saveData()
    }
    
    func renameUserCategory(_ category: UserCategory, to newName: String) {
        guard let index = userCategories.firstIndex(where: { $0.id == category.id }) else { return }
        userCategories[index].name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        saveData()
    }
    
    func updateUserCategoryIcon(_ category: UserCategory, to systemName: String) {
        guard let index = userCategories.firstIndex(where: { $0.id == category.id }) else { return }
        userCategories[index].iconSystemName = systemName
        saveData()
    }
    
    func updateUserCategoryColor(_ category: UserCategory, to colorName: String) {
        guard let index = userCategories.firstIndex(where: { $0.id == category.id }) else { return }
        userCategories[index].colorName = colorName
        saveData()
    }

    func getCategory(id: UUID) -> UserCategory? {
        return userCategories.first(where: { $0.id == id })
    }
    
    func resolveCategory(id: UUID) -> UserCategory {
        if let category = getCategory(id: id) {
            return category
        }
        // Fallback
        if let first = userCategories.first {
            return first
        }
        return UserCategory.createDefault()
    }
    
    func updateCustomDateRange(startDate: Date, endDate: Date) {
        customStartDate = startDate
        customEndDate = endDate
        saveData()
    }
    
    // MARK: - Time Period Filtering
    
    func getFilteredExpenses() -> [Expense] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimePeriod {
        case .today:
            return expenses.filter { calendar.isDateInToday($0.date) }
        case .thisWeek:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return [] }
            return expenses.filter { $0.date >= weekStart && $0.date <= now }
        case .all:
            return expenses
        case .currentMonth:
            return expenses.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .lastMonth:
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else { return [] }
            return expenses.filter { calendar.isDate($0.date, equalTo: lastMonth, toGranularity: .month) }
        case .customMonth:
            return expenses.filter { expense in
                expense.date >= customStartDate && expense.date <= customEndDate
            }
        }
    }
    
    func getTotalExpensesForPeriod() -> Double {
        let filteredExpenses = getFilteredExpenses()
        return filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - AI Coach Intelligence
    
    func getUpcomingBillReminders() -> [String] {
        let calendar = Calendar.current
        let now = Date()
        let twoDaysFromNow = calendar.date(byAdding: .day, value: 2, to: now)!
        
        var reminders: [String] = []
        let salary = getCurrentSalaryForPeriod()
        let spent = getTotalExpensesForPeriod()
        let remainingBudget = max(0, salary - spent)
        
        for bill in recurringExpenses {
            let nextDate = bill.nextDueDate
            guard nextDate >= now && nextDate <= twoDaysFromNow else { continue }
            
            let budgetAfterBill = remainingBudget - bill.amount
            let daysUntil = calendar.dateComponents([.day], from: now, to: nextDate).day ?? 0
            
            let dayText = daysUntil == 0 ? "today".localized : "tomorrow".localized
            let formattedRemainder = CurrencyFormatter.format(budgetAfterBill, currency: user.currency)
            
            // Note: Since .localized doesn't support placeholders for placeholders in StringExtensions yet,
            // we'll format it normally or add keys.
            let message = "Reminder: \(bill.title) is due \(dayText). You'll have \(formattedRemainder) left after this payment."
            reminders.append(message)
        }
        
        return reminders
    }
    
    func getRemainingBudgetForPeriod() -> Double {
        let salary = getCurrentSalaryForPeriod()
        return max(0, salary - getTotalExpensesForPeriod())
    }
    
    func getCurrentSalaryForPeriod() -> Double {
        switch selectedTimePeriod {
        case .today:
            let monthSalary = getCurrentMonthSalary()
            let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
            return monthSalary / Double(daysInMonth)
        case .thisWeek:
            let monthSalary = getCurrentMonthSalary()
            let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
            return (monthSalary / Double(daysInMonth)) * 7.0
        case .all:
            return monthlySalaries.reduce(0) { $0 + $1.amount }
        case .currentMonth:
            return getCurrentMonthSalary()
        case .lastMonth:
            let calendar = Calendar.current
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            let year = calendar.component(.year, from: lastMonth)
            let month = calendar.component(.month, from: lastMonth)
            return getSalaryForMonth(month: month, year: year)
        case .customMonth:
            // For custom month, calculate salary based on the date range
            let calendar = Calendar.current
            let startYear = calendar.component(.year, from: customStartDate)
            let startMonth = calendar.component(.month, from: customStartDate)
            let endYear = calendar.component(.year, from: customEndDate)
            let endMonth = calendar.component(.month, from: customEndDate)
            
            // If the range spans multiple months, sum up the salaries
            if startYear == endYear && startMonth == endMonth {
                return getSalaryForMonth(month: startMonth, year: startYear)
            } else {
                // For multi-month ranges, calculate proportional salary
                let daysInRange = calendar.dateComponents([.day], from: customStartDate, to: customEndDate).day ?? 1
                let totalDaysInStartMonth = calendar.range(of: .day, in: .month, for: customStartDate)?.count ?? 30
                let startMonthSalary = getSalaryForMonth(month: startMonth, year: startYear)
                return (startMonthSalary / Double(totalDaysInStartMonth)) * Double(daysInRange)
            }
        }
    }
    
    // Return (Category Name, Amount, Color, Icon)
    // Supports User Categories
    func getCategoryBreakdownForPeriod() -> [(name: String, amount: Double, color: Color, icon: String)] {
        let filteredExpenses = getFilteredExpenses()
        var categoryTotals: [UserCategory: Double] = [:]
        
        for expense in filteredExpenses {
            let category = resolveCategory(id: expense.categoryId)
            categoryTotals[category, default: 0] += expense.amount
        }
        
        return categoryTotals.map { category, amount in
            (name: category.name, amount: amount, color: category.color, icon: category.iconSystemName)
        }.sorted { $0.amount > $1.amount }
    }
    
    func getDailyAverageForPeriod() -> Double {
        let filteredExpenses = getFilteredExpenses()
        guard !filteredExpenses.isEmpty else { return 0 }
        let total = filteredExpenses.reduce(0) { $0 + $1.amount }
        // Average per distinct calendar day that has spending.
        let calendar = Calendar.current
        let distinctDays = Set(filteredExpenses.map { calendar.startOfDay(for: $0.date) }).count
        return total / Double(max(1, distinctDays))
    }

    func getWeeklyAverageForPeriod() -> Double {
        let filteredExpenses = getFilteredExpenses()
        guard !filteredExpenses.isEmpty else { return 0 }
        let total = filteredExpenses.reduce(0) { $0 + $1.amount }
        // Average per distinct calendar week that has spending.
        let calendar = Calendar.current
        let distinctWeeks = Set(filteredExpenses.map { expense -> DateComponents in
            calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: expense.date)
        }).count
        return total / Double(max(1, distinctWeeks))
    }
    
    func getProgressPercentageForPeriod() -> Double {
        let salary = getCurrentSalaryForPeriod()
        guard salary > 0 else { return 0 }
        return min(getTotalExpensesForPeriod() / salary, 1.0)
    }
}

