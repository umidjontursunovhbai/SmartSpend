import Foundation

struct SpendableTodaySnapshot: Equatable {
    let monthlyIncome: Double
    let spentThisMonth: Double
    let upcomingRecurring: Double
    let remainingBeforeBills: Double
    let availableAfterBills: Double
    let daysRemaining: Int
    let spendableToday: Double
}

enum BudgetPeriodCalculator {
    static func monthInterval(
        containing date: Date,
        calendar: Calendar = .current
    ) -> DateInterval {
        calendar.dateInterval(of: .month, for: date)
            ?? DateInterval(start: date, duration: 0)
    }

    static func expenses(
        _ expenses: [Expense],
        in interval: DateInterval
    ) -> [Expense] {
        expenses.filter { interval.contains($0.date) }
    }

    static func total(
        for expenses: [Expense],
        in interval: DateInterval
    ) -> Double {
        self.expenses(expenses, in: interval)
            .reduce(0) { $0 + $1.amount }
    }

    static func totalsByCategory(
        for expenses: [Expense],
        in interval: DateInterval
    ) -> [UUID: Double] {
        expenses.reduce(into: [:]) { totals, expense in
            guard interval.contains(expense.date) else { return }
            totals[expense.categoryId, default: 0] += expense.amount
        }
    }

    static func projectedRecurringTotal(
        recurringExpenses: [RecurringExpense],
        in interval: DateInterval
    ) -> Double {
        recurringExpenses.reduce(0) { total, recurring in
            total + projectedTotal(for: recurring, in: interval)
        }
    }

    static func spendableToday(
        monthlyIncome: Double,
        expenses: [Expense],
        recurringExpenses: [RecurringExpense],
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> SpendableTodaySnapshot {
        let month = monthInterval(containing: date, calendar: calendar)
        let today = max(calendar.startOfDay(for: date), month.start)
        let remainingInterval = DateInterval(start: today, end: month.end)
        let spent = total(for: expenses, in: month)
        let upcoming = projectedRecurringTotal(
            recurringExpenses: recurringExpenses,
            in: remainingInterval
        )
        let remainingBeforeBills = monthlyIncome - spent
        let availableAfterBills = remainingBeforeBills - upcoming
        let daysRemaining = max(
            calendar.dateComponents([.day], from: today, to: month.end).day ?? 1,
            1
        )

        return SpendableTodaySnapshot(
            monthlyIncome: monthlyIncome,
            spentThisMonth: spent,
            upcomingRecurring: upcoming,
            remainingBeforeBills: remainingBeforeBills,
            availableAfterBills: availableAfterBills,
            daysRemaining: daysRemaining,
            spendableToday: max(availableAfterBills, 0) / Double(daysRemaining)
        )
    }

    private static func projectedTotal(
        for recurring: RecurringExpense,
        in interval: DateInterval
    ) -> Double {
        guard recurring.isActive else { return 0 }
        if let endDate = recurring.endDate, endDate < interval.start {
            return 0
        }

        var nextDate = recurring.nextDueDate
        var total = 0.0
        var iterations = 0

        while nextDate < interval.start && iterations < 400 {
            nextDate = recurring.recurrenceType.nextDate(from: nextDate)
            iterations += 1
        }

        while nextDate < interval.end && iterations < 400 {
            if let endDate = recurring.endDate, nextDate > endDate {
                break
            }

            total += recurring.amount
            nextDate = recurring.recurrenceType.nextDate(from: nextDate)
            iterations += 1
        }

        return total
    }
}
