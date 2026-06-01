# 💸 SmartSpend

**The intelligent, privacy-focused expense tracker for iOS — with home/lock-screen Widgets and a Control Center shortcut.**

SmartSpend helps you master your finances with a clean, native iOS design. No accounts to create, no servers to trust — your data lives entirely on your device.

## ✨ Key Features

*   **🏠 At-a-glance Dashboard**: See what matters *right now* — remaining budget this month, your proportional daily allowance, today/this week/this month totals, upcoming bills, recent expenses, and budget alerts.
*   **🧠 Smart Learning**: The app learns your spending habits (prices and categories) and auto-fills details as you type, using keyword + fuzzy matching.
*   **📊 Proportional Budgeting**: Automatically calculates how much you can still spend per day based on your monthly income and what's left.
*   **🔍 Fast Filtering**: Quick time periods (All / Today / Yesterday / This Week / This Month) as a segmented control, plus a filter sheet with **multi-select categories** and custom date ranges.
*   **🔄 Recurring Expenses**: Track subscriptions, rent, and bills with flexible schedules so you never miss a payment.
*   **📉 Powerful Analytics**: Donut category breakdown, spending-trend charts, peak spending days, and per-category budget progress.
*   **💡 Insights**: Locally-computed spending insights — budget warnings, month-over-month trends, top categories, biggest expense, and busiest day.
*   **💰 Budgets & Goals**: Set category budgets and savings goals, and track progress in real time.
*   **🏷️ Custom Categories**: Fully customizable categories with your own icons and colors.
*   **📥 Import & Export**: Full CSV support to move your data in and out freely.
*   **🌍 Global Support**: Multi-currency and multi-language support (English, Uzbek, and more).

## 📱 The App

SmartSpend is organized into five tabs:

| Tab | What it's for |
|-----|---------------|
| **Dashboard** | Glanceable "now" view — remaining budget, daily allowance, today/week/month totals, upcoming bills, recent expenses, alerts |
| **Expenses** | Full, searchable list grouped by day, with segmented time filters and a multi-select category filter sheet |
| **Analytics** | Deep analysis — trend charts, category donut, peak days, budget progress |
| **Recurring** | Manage recurring expenses and see upcoming occurrences |
| **Settings** | Income, currency, language, categories, budgets & goals, import/export, deleted expenses, insights |

## 🪟 Widgets

SmartSpend offers a full suite of widgets across every iOS surface:

### Home Screen
| Size | What it shows |
|------|--------------|
| **Small** | Today's spending + monthly budget progress bar |
| **Medium** | Today & This Month spending cards + remaining budget |
| **Large** | Full overview — spending cards, budget bar, top 3 categories, and an **interactive Add Expense button** |

### Lock Screen
| Style | What it shows |
|-------|--------------|
| **Circular** | Budget ring gauge — green → orange → red as you spend; today's total in the centre |
| **Rectangular** | Today + Month amounts with an optional budget progress bar |
| **Inline** | Single-line today's total above the clock |

### Control Center (iOS 18+)
Add the **SmartSpend → Add Expense** button to your Control Center or Lock Screen and jump straight to the Add Expense screen with one tap.

## 🚀 Getting Started

1.  **Clone the repo**:
    ```bash
    git clone https://github.com/JohnUfo/SmartSpend.git
    ```
2.  **Open in Xcode**:
    Double-click `SmartSpend.xcodeproj`.
3.  **Set your signing & App Group** *(required for widgets)*:
    - Select each target (**SmartSpend** and the **Widget** extension) → Signing & Capabilities → set your own Team.
    - Add an **App Group** capability to both targets and give them the **same** identifier (e.g. `group.<your-bundle-id>`). The app and its widgets share data through this group.
4.  **Run**:
    Select a simulator or device and hit **Play** (Cmd+R).
    *Requires Xcode 16.0+ and iOS 17.0+.*

## 🛠 Tech Stack

*   **Language**: Swift 6
*   **UI Framework**: SwiftUI (native iOS design — `List` / `Form`, `.searchable`, `ContentUnavailableView`, system materials)
*   **Architecture**: MVVM with a shared `DataManager` (`ObservableObject` singleton)
*   **Charts**: Apple Swift Charts
*   **Storage**: JSON persisted to `UserDefaults`, shared with widgets via App Groups
*   **Widgets**: WidgetKit — home screen, lock screen, and Control Center
*   **Intents**: AppIntents — interactive widget buttons (iOS 17+), Control Center action (iOS 18+)

## 🔐 Privacy

Everything stays on-device. There are no accounts, no analytics, and no network calls for your financial data — expenses, salaries, budgets, and categories are stored locally and shared only with the SmartSpend widgets on your device.

## 📞 Support

Need help or have suggestions?
- **In-app Insights**: Open **Settings → Insights** for a personalized read on your spending.
- **Email**: tursunov.umidjon.uz@gmail.com

---
*Built with ❤️ for a smarter financial future*
