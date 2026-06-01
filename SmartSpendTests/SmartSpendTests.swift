//
//  SmartSpendTests.swift
//  SmartSpendTests
//
//  Created by Umidjon Tursunov on 23/08/2025.
//

import Testing
import Foundation
@testable import SmartSpend

@Suite("SmartSpend Tests")
struct SmartSpendTests {

    @Test("Example test")
    func example() async throws {
        #expect(true, "This test should pass")
    }

    @Test("Expense creation")
    func expenseCreation() async throws {
        let categoryId = UUID()
        let expense = Expense(
            title: "Test Expense",
            amount: 100.0,
            categoryId: categoryId,
            date: Date()
        )
        
        #expect(expense.title == "Test Expense")
        #expect(expense.amount == 100.0)
        #expect(expense.categoryId == categoryId)
    }
    
    @Test("Monthly salary creation")
    func monthlySalaryCreation() async throws {
        let salary = MonthlySalary(
            year: 2025,
            month: 11,
            amount: 5000.0,
            currency: .usd
        )
        
        #expect(salary.year == 2025)
        #expect(salary.month == 11)
        #expect(salary.amount == 5000.0)
        #expect(salary.currency == .usd)
        #expect(salary.id != nil)
    }

    @Test("Imported category gets default style")
    func importedCategoryDefaultStyle() async throws {
        let food = UserCategory.imported(name: "Food")
        let other = UserCategory.imported(name: "Other")

        #expect(food.iconSystemName == "fork.knife")
        #expect(food.colorName == "systemOrange")
        #expect(other.iconSystemName == "tag.fill")
        #expect(other.colorName == "systemGray")
    }
}
