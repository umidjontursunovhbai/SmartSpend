# 💰 SmartSpend

A powerful iOS expense tracking and budget management app built with SwiftUI and modern Apple frameworks.

## 📱 Features

### Core Features
- **📊 Expense Tracking** - Track your daily expenses with ease
- **💰 Budget Management** - Set and monitor budgets by category
- **📈 Analytics & Insights** - Visualize spending trends with interactive charts powered by Swift Charts
- **🎯 Spending Goals** - Set financial goals and track your progress
- **🔄 Recurring Expenses** - Manage subscriptions and regular payments automatically
- **🎨 Custom Categories** - Create personalized expense categories with icons and colors

### Advanced Features
- **🧠 Smart Learning** - AI-powered pattern recognition suggests categories based on your spending habits
- **💵 Monthly Salary Tracking** - Set your monthly income and track remaining budget
- **📤 Data Export/Import** - Export and import your financial data in CSV or JSON formats
- **🗑️ Deleted Expenses** - Recover accidentally deleted expenses from trash
- **🌍 Multi-language Support** - Localized interface for global users
- **🌓 Dark Mode** - Beautiful interface optimized for both light and dark appearances
- **💱 Multi-Currency Support** - Track expenses in your preferred currency

## 🛠️ Technical Stack

- **Language:** Swift
- **Framework:** SwiftUI
- **Architecture:** MVVM with ObservableObject pattern
- **Data Persistence:** UserDefaults with Codable
- **Charts:** Swift Charts framework for analytics
- **Minimum iOS Version:** iOS 17.0+
- **Platform Support:** iOS, iPadOS

## 📂 Project Structure

```
SmartSpend/
├── SmartSpendApp.swift              # Main app entry point
├── Views/
│   ├── ContentView.swift            # Root view with initialization
│   ├── MainTabView.swift            # Tab-based navigation (Dashboard, Expenses, Analytics, Recurring, Settings)
│   ├── DashboardView.swift          # Main dashboard with spending overview
│   ├── ExpenseListView.swift        # Expense list and management
│   ├── AddExpenseView.swift         # Add new expenses with smart suggestions
│   ├── AnalyticsView.swift          # Charts and spending insights
│   ├── RecurringExpensesView.swift  # Recurring expense management
│   ├── CategoryManagementView.swift # Custom category system
│   ├── BudgetSettingsView.swift     # Budget configuration
│   ├── SettingsView.swift           # App settings and preferences
│   ├── MonthlySalaryView.swift      # Monthly income tracking
│   ├── DeletedExpensesView.swift    # Trash/recovery system
│   └── DataExportView.swift         # Export functionality UI
│       DataImportView.swift         # Import functionality UI
├── Models/
│   ├── DataManager.swift            # Core data management (singleton pattern)
│   ├── Expense.swift                # Expense model
│   ├── ExpenseCategory.swift        # Category definitions
│   ├── RecurringExpense.swift       # Recurring expense model
│   ├── Budget.swift                 # Budget model
│   ├── SpendingGoal.swift           # Spending goal model
│   ├── LearnedPattern.swift         # Smart learning patterns
│   └── User.swift                   # User preferences and settings
├── Utilities/
│   ├── DataExporter.swift           # Export functionality (CSV, JSON)
│   ├── DataImporter.swift           # Import functionality (CSV, JSON)
│   ├── CurrencyFormatter.swift      # Currency formatting utilities
│   ├── TabManager.swift             # Tab navigation management
│   └── Extensions/
│       └── String+Localization.swift # Localization extensions
└── Resources/
    └── Localizable.strings          # Multi-language support
```

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- macOS 14.0+ (for development)

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/YourUsername/SmartSpend.git
cd SmartSpend
```

2. **Open the project in Xcode:**
```bash
open SmartSpend.xcodeproj
# or if you're using a workspace:
# open SmartSpend.xcworkspace
```

3. **Select your target device:**
   - Choose your device or simulator from the scheme menu in Xcode
   - For best experience, use iOS 17.0 or later

4. **Build and run:**
   - Press ⌘ + R or click the Run button
   - The app will launch on your selected device/simulator

### First Time Setup
When you first launch SmartSpend:
1. The app will initialize with default categories
2. Optionally set your monthly salary in Settings
3. Start adding your expenses and explore the features!

## 💡 Usage

### Adding an Expense
1. Tap the **+** button on the Dashboard or Expenses tab
2. Enter expense details (amount, title, category)
3. The app will suggest categories based on your spending patterns
4. Optional: Add notes or set as recurring
5. Tap "Add Expense" to save

### Managing Recurring Expenses
1. Navigate to the **Recurring** tab
2. Tap the **+** button to add a new recurring expense
3. Set the frequency (daily, weekly, monthly, yearly)
4. The app will automatically create expenses based on the schedule

### Setting a Budget
1. Navigate to the **Settings** tab
2. Select "Budget Goals"
3. Choose a category
4. Set your budget limit and time period
5. Track your progress in the Analytics tab

### Viewing Analytics
1. Open the **Analytics** tab
2. View spending breakdown by category with interactive charts
3. Switch between weekly and monthly views
4. See peak spending days and patterns
5. Monitor budget progress with visual indicators

### Setting Monthly Salary
1. Go to **Settings** tab
2. Tap "Monthly Salaries"
3. Enter your income for the current month
4. View remaining budget on the Dashboard

### Exporting/Importing Data
1. In **Settings**, tap "Export Data" or "Import Data"
2. For export: Choose data types (expenses, budgets, etc.) and format (CSV or JSON)
3. For import: Select a file from your device
4. The app supports CSV files from various sources and intelligently maps columns

## 🔐 Privacy & Data

SmartSpend is designed with privacy in mind:
- **100% Local Storage** - All data is stored locally on your device using UserDefaults
- **No Cloud Services** - Your financial data never leaves your device
- **No Account Required** - Use the app without creating an account or signing in
- **No Analytics or Tracking** - We don't collect any usage data or personal information
- **Export Your Data Anytime** - Full control over your data with export/import functionality

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### How to Contribute

1. **Fork the project**
2. **Create your feature branch**
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. **Commit your changes**
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```
4. **Push to the branch**
   ```bash
   git push origin feature/AmazingFeature
   ```
5. **Open a Pull Request**

### Contribution Guidelines
- Follow Swift naming conventions and style guidelines
- Write clear commit messages
- Update documentation when adding new features
- Test your changes thoroughly before submitting
- Keep pull requests focused on a single feature or fix

## 🐛 Bug Reports & Feature Requests

Found a bug or have an idea for a new feature?
- Open an issue on GitHub with a clear description
- For bugs, include steps to reproduce and expected behavior
- For features, explain the use case and why it would be valuable

## 📝 License

This project is available for personal and educational use. Please contact the author for commercial licensing.

## 👤 Author

**Umidjon Tursunov**

Feel free to reach out for questions, suggestions, or collaboration opportunities!

## 📧 Contact & Support

- **GitHub Issues:** For bug reports and feature requests
- **Discussions:** For general questions and community support

## 🙏 Acknowledgments

- Built with Apple's **SwiftUI** framework
- Charts powered by **Swift Charts** framework
- Uses **SF Symbols** for iconography
- Inspired by modern personal finance apps and Apple's Human Interface Guidelines

## ✨ Key Highlights

- **Smart Learning**: The app learns from your spending patterns and suggests appropriate categories
- **Beautiful Charts**: Interactive visualizations built with Swift Charts
- **Flexible Export**: Support for both CSV and JSON formats for data portability
- **Deleted Items Recovery**: Safely recover accidentally deleted expenses
- **Custom Categories**: Create unlimited custom expense categories with personalized icons and colors
- **Recurring Expense Automation**: Set it once, and the app handles the rest

## ❓ FAQ

### Is my financial data secure?
Yes! All your data is stored locally on your device using iOS's secure storage. We don't collect or transmit any data to external servers.

### Can I sync my data across multiple devices?
Currently, the app stores data locally. iCloud sync is planned for a future release (see Roadmap).

### What currencies are supported?
The app supports multiple currencies. You can select your preferred currency in the Settings tab.

### Can I export my data?
Yes! You can export all your data in CSV or JSON format from the Settings tab. This allows you to backup your data or use it in other apps.

### How does the Smart Learning feature work?
The app analyzes your spending patterns (titles and amounts) and learns to suggest appropriate categories for new expenses, making data entry faster over time.

### Can I recover deleted expenses?
Yes! Deleted expenses are moved to trash and can be recovered from the "Deleted Expenses" section in Settings.

### Does the app work offline?
Absolutely! SmartSpend works 100% offline since all data is stored locally on your device.

## 📊 Roadmap

### ✅ Shipped
- [x] **iOS Widgets** - Home screen (small/medium/large with interactive Add Expense button), lock screen (circular/rectangular/inline), and Control Center shortcut (iOS 18+)

### Planned Features
- [ ] **iCloud Sync** - Sync expenses across devices
- [ ] **Apple Watch App** - Track expenses from your wrist
- [ ] **Advanced Reporting** - Detailed PDF reports with charts
- [ ] **Receipt Scanning** - OCR-powered receipt capture
- [ ] **Budget Alerts** - Notifications when approaching budget limits
- [ ] **Family Sharing** - Share budgets with family members
- [ ] **Banking Integration** - Automatic expense import from banks
- [ ] **AI Insights** - Advanced spending insights and recommendations
- [ ] **Siri Shortcuts** - Add expenses with voice commands
- [ ] **Split Expenses** - Track shared expenses with friends

### Future Considerations
- SwiftData migration for improved performance
- visionOS support
- macOS companion app

---

**Made with ❤️ using SwiftUI**
