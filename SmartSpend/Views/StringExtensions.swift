//
//  StringExtensions.swift
//  SmartSpend
//
//  Created on 11/22/2025.
//

import Foundation

extension String {
    /// Returns the localized version of the string.
    /// For now, returns the English translation directly.
    var localized: String {
        // Map of localization keys to English text
        let translations: [String: String] = [
            // Tab Bar
            "dashboard": "Dashboard",
            "expenses": "Expenses",
            "analytics": "Analytics",
            "recurring": "Recurring",
            "settings": "Settings",
            
            // Common Actions
            "cancel": "Cancel",
            "save": "Save",
            "delete": "Delete",
            "done": "Done",
            "clear": "Clear",
            "ok": "OK",
            "change": "Change",
            "manage": "Manage",
            "reset": "Reset",
            
            // Settings
            "profile": "Profile",
            "monthly_salaries": "Monthly Salaries",
            "currency": "Currency",
            "language": "Language",
            "statistics": "Statistics",
            "total_expenses": "Total Expenses",
            "remaining_budget": "Remaining Budget",
            "data_management": "Data Management",
            "import_data": "Import Data",
            "export_data": "Export Data",
            "deleted_expenses": "Deleted Expenses",
            "clear_all_data": "Clear All Data",
            "clear_all_data_message": "Are you sure you want to delete all expenses, patterns, and salary data? This action cannot be undone.",
            "features": "Features",
            "budget_goals": "Budget Goals",
            "categories": "Categories",
            "about": "About",
            "not_set": "Not Set",
            "smartspend": "SmartSpend",
            "smart_learning": "Smart Learning",
            
            // Dashboard
            "time_period": "Time Period",
            "budget_overview": "Budget Overview",
            "budget_used": "Budget Used",
            "spent": "Spent",
            "remaining": "Remaining",
            "category_breakdown": "Category Breakdown",
            "spending_trends": "Spending Trends",
            "daily_avg": "Daily Average",
            "weekly_avg": "Weekly Average",
            "of_total": "of total",
            "monthly_salary": "Monthly Salary",
            "no_expenses_yet": "No expenses yet",
            "budget_details": "Budget Details",
            // Dashboard (home)
            "remaining_this_month": "Remaining This Month",
            "spend_per_day_format": "You can spend %@/day",
            "income_not_set": "Set your monthly income to track your budget.",
            "set_income": "Set Income",
            "this_week": "This Week",
            "recent_expenses": "Recent Expenses",
            "view_all": "View All",
            "upcoming_bills": "Upcoming Bills",
            "budget_alerts": "Budget Alerts",
            "over_budget": "Over budget",
            "near_limit": "Near limit",
            "due_today": "Due today",
            "due_tomorrow": "Due tomorrow",
            "due_in_days_format": "Due in %d days",
            "transactions_count_format": "%d transactions",
            "one_transaction": "1 transaction",
            "custom_date_range": "Custom Date Range",
            "from": "From",
            "to": "To",
            "select_custom_date_range": "Select Custom Date Range",
            "tap_from_select_start": "Tap 'From' to select start date",
            "select_end_date": "Select end date",
            
            // Expense List
            "time_period_all": "All Time",
            "time_period_today": "Today",
            "time_period_this_week": "This Week",
            "time_period_this_month": "This Month",
            "time_period_last_month": "Last Month",
            "time_period_custom": "Custom",
            "search_expenses": "Search expenses...",
            "all": "All",
            "filter": "Filter",
            "filter_category_hint": "Select one or more categories. None selected shows all.",
            "no_expenses_found": "No expenses found",
            "try_adjusting_filters": "Try adjusting your filters",
            "date_from": "Date From",
            "date_to": "Date To",
            "date_range_instruction_first": "Select a start date",
            "date_range_instruction_second": "Select an end date",
            
            // Add/Edit Expense
            "add_expense": "Add Expense",
            "expense_title_placeholder": "Enter expense title...",
            "category": "Category",
            "select_category": "Select Category",
            "create_new_category": "Create New Category",
            "column_date": "Date",
            "expense_details": "Expense Details",
            "smart_suggestions_footer": "SmartSpend learns from your spending patterns to provide smart suggestions",
            "make_recurring": "Make Recurring",
            "frequency": "Frequency",
            "set_end_date": "Set End Date",
            "end_date": "End Date",
            "recurring_footer_format": "This expense will repeat %@",
            
            // Monthly Salary
            "month_year": "Month & Year",
            "month": "Month",
            "year": "Year",
            "amount": "Amount",
            "monthly_salary_title": "Monthly Salary",
            
            // Analytics
            "analytics_title": "Analytics",
            "timeframe_week": "Week",
            "timeframe_month": "Month",
            "timeframe_year": "Year",
            "compare_to": "Compare to:",
            "compare_previous_period": "Previous period",
            "compare_same_last_year": "Same period last year",
            "vs_period_pct_format": "%@ vs %@",
            "comparison_total_format": "vs %@ · %@",
            "tap_to_return_today": "Tap to return to current",
            "monthly_history": "Last 12 Months",
            "tap_month_hint": "Use ‹ › above to browse months",
            "year_to_date": "Year to Date",
            "vs_last_year_format": "vs %@ same time last year",
            "no_last_year_data": "No data from last year yet",
            "budgets": "Budgets",
            "budget_progress": "Budget Progress",
            "no_budget_set": "No budget set",
            "set_budget": "Set Budget",
            "peak_days": "Peak Spending Days",
            "increase": "increase",
            "decrease": "decrease",
            "no_change": "No change from previous period",
            "today": "Today",
            "yesterday": "Yesterday",
            
            // Currency Selection
            "select_currency": "Select Currency",
            "all_monetary_values": "All monetary values will be displayed in the selected currency",
            
            // Language Selection
            "select_language": "Select Language",
            "app_interface_language": "The app interface will be displayed in the selected language",
            
            // Deleted Expenses
            "search_deleted_expenses": "Search deleted expenses...",
            "no_deleted_expenses": "No deleted expenses",
            "no_deleted_expenses_found": "No deleted expenses found",
            "try_adjusting_filters_deleted": "Try adjusting your filters",
            "deleted_expenses_appear_here": "Deleted expenses will appear here",
            "restore_button": "Restore",
            "delete_button": "Delete Permanently",
            "deleted_expenses_title": "Deleted Expenses",
            
            // Data Export
            "export_data_types": "Data to Export",
            "export_format_section": "Export Format",
            "date_range_section": "Date Range",
            "use_date_range": "Use Date Range",
            "start_date": "Start Date",
            "preview_section": "Preview",
            "export_summary": "Export Summary",
            "data_types_label": "Data Types",
            "selected_count": "%d selected",
            "format_label": "Format",
            "date_range_label": "Date Range",
            "estimated_size_label": "Estimated Size",
            "export_data_title": "Export Data",
            "export_button": "Export",
            "export_status_title": "Export Status",
            "export_success": "Data exported successfully",
            "export_failed": "Export failed. Please try again.",
            
            // Data Import
            "import_expenses_title": "Import Expenses",
            "import_expenses_subtitle": "Import your expenses from a CSV file",
            "import_status": "Import Status",
            "confirm_import": "Confirm Import",
            "import_all_expenses_format": "Import %d expenses",
            "confirm_import_message": "This will add all the expenses from the CSV file to your existing data.",
            "select_csv_file": "Select CSV File",
            "select_csv_subtitle": "Choose a CSV file containing your expenses",
            "how_to_import_title": "How to Import",
            "import_step_1": "1. Prepare your CSV file with expense data",
            "import_step_2": "2. Tap 'Select CSV File' to choose your file",
            "import_step_3": "3. Review the preview and tap Import",
            "file_selected": "File Selected",
            "preview": "Preview",
            "total_rows_format": "Total Rows: %d",
            "detected_columns": "Detected Columns",
            "sample_data_first_three": "Sample Data (First 3 Rows)",
            "row_number_format": "Row %d",
            "importing": "Importing...",
            "import_expenses_cta": "Import Expenses",
            "cannot_access_file": "Cannot access the selected file",
            "cannot_read_file_debug": "Cannot read file. Please ensure it's a valid CSV file.",
            "import_success_count": "Successfully imported %d expenses",
            "import_partial_with_errors": "Imported %d expenses with %d errors",
            "import_failed_error": "Import failed: %@",
            "csv_format_guide": "CSV Format Guide",
            "csv_format_subtitle": "Learn how to format your CSV file for import",
            "smartspend_format": "SmartSpend Format",
            "smartspend_format_desc": "The standard format with exact column names:",
            "required": "Required",
            "column_title": "Title",
            "column_amount": "Amount",
            "column_category": "Category",
            "custom_format": "Custom Format",
            "custom_format_desc": "Flexible column names that SmartSpend will detect:",
            "column_title_name_description": "Title/Name/Description",
            "any_of_these": "Any of these",
            "column_amount_price_cost": "Amount/Price/Cost",
            "column_category_type": "Category/Type",
            "tips_title": "Tips",
            "tip_case_insensitive": "Column names are case-insensitive",
            "tip_date_formats": "Dates can be in various formats (MM/DD/YYYY, YYYY-MM-DD, etc.)",
            "tip_categories_auto": "Unknown categories will be auto-assigned",
            "tip_currency_symbols": "Currency symbols in amounts will be ignored",
            "required_columns": "Required Columns",
            "example_header": "Example",
            
            // Recurring Expenses
            "recurring_expenses_title": "Recurring Expenses",
            "process": "Process",
            "no_recurring_expenses": "No Recurring Expenses",
            "set_up_recurring_expenses": "Set up expenses that repeat automatically like rent, subscriptions, or bills",
            "next": "Next",
            "inactive": "Inactive",
            "expired": "Expired",
            "overdue": "Overdue",
            "due": "Due",
            "active": "Active",
            
            // Add/Edit Recurring Expense
            "add_recurring_expense": "Add Recurring Expense",
            "edit_recurring_expense": "Edit Recurring Expense",
            "title": "Title",
            "recurrence": "Recurrence",
            "status": "Status",
            "last_processed": "Last Processed",
            "next_due": "Next Due",
            "upcoming_occurrences": "Upcoming Occurrences",
            "start": "Start",
            
            // Problem Expenses
            "problem_expenses": "Problem Expenses",
            "problem_expenses_title": "Problem Expenses",
            "problem_expenses_description": "These expenses have unrecognized categories and need your review. Tap on any expense to edit its category.",
            "expenses_needing_review": "Expenses Needing Review",
            "needs_review": "Needs Review",
            "no_problem_expenses_title": "All Clear!",
            "no_problem_expenses_message": "All your expenses are properly categorized. Great job keeping your data organized!",
            "auto_categorize_all": "Auto-Categorize All",
            "delete_all": "Delete All",
            "apply_category_to_all_title": "Apply to Similar Expenses?",
            "apply_category_to_all_message": "There are other expenses with the title '%@'. Would you like to apply the same category to all of them?",
            "apply_to_all": "Apply to All",
            "just_this_one": "Just This One",
            
            // Support
            "support": "Support",
            "ai_chat": "AI Support Chat",
            "email_us": "Email Support",
            "privacy_policy": "Privacy Policy",
            "chat_placeholder": "How can I help you today?",
            "support_agent_name": "SmartSpend AI",
            "support_agent_status": "Always Active",
            
            // AI Coach Tips
            "coach_tip_spending_surge": "Heads up! Your spending has surged by %@ this week. You might want to review your recent purchases.",
            "coach_tip_budget_warning": "Caution: You've used %d%% of your %@ budget. You're approaching your limit!",
            "coach_tip_budget_exceeded": "Alert: You've exceeded your monthly budget for %@. Let's try to slow down in this category.",
            "coach_tip_savings_success": "Excellent work! Your spending is down 20% compared to last week. You're becoming a savings master!",
            "coach_tip_set_budget": "Pro Tip: Setting monthly category budgets helps you save 15% more on average. Try setting one in Budget Settings!"
        ]
        
        // Return the translation if found, otherwise return the key itself
        return translations[self] ?? self
    }
    
    /// Returns the localized version of the string with arguments.
    /// - Parameters:
    ///   - arguments: The arguments to substitute in the localized string format.
    /// - Returns: The formatted localized string.
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
