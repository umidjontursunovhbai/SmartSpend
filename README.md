# 💸 SmartSpend v1.1.0

**The intelligent, privacy-focused expense tracker for iOS — now with Widgets, Lock Screen support, and a Control Center shortcut.**

SmartSpend helps you master your finances with a beautiful, native design. No accounts to create, no servers to trust — your data lives on your device.

## ✨ Key Features

*   **🧠 Smart Learning**: The app learns your spending habits (prices and categories) to auto-fill details for you instantly.
*   **📅 Today & This Week Views**: Get instant snapshots of your current spending with dedicated "Today" and "This Week" filters.
*   **📊 Proportional Budgeting**: Automatically calculates your remaining daily and weekly budget based on your monthly income.
*   **🔄 Recurring Expenses**: Track subscriptions, rent, and bills so you never miss a payment.
*   **📉 Powerful Analytics**: Visualize your spending with interactive charts, monthly comparisons, and category breakdowns.
*   **💰 Budget & Goals**: Set category-specific budgets and track your progress in real-time.
*   **⚠️ Dynamic Categories**: Completely customizable category system with custom icons and colors.
*   **📥 Import & Export**: Full CSV support to move your data in and out freely.
*   **🌍 Global Support**: Multi-currency and multi-language support (English, Uzbek, and more).
*   **🎨 Premium Native UI**: A stunning, fluid SwiftUI interface designed specifically for iOS.

## 🪟 Widgets

SmartSpend offers a full suite of widgets across every iOS surface:

### Home Screen Widgets
| Size | What it shows |
|------|--------------|
| **Small** | Today's spending + monthly budget progress bar |
| **Medium** | Today & This Month spending cards + remaining budget |
| **Large** | Full overview — spending cards, budget bar, top 3 categories, and an **interactive Add Expense button** |

### Lock Screen Widgets
| Style | What it shows |
|-------|--------------|
| **Circular** | Budget ring gauge — fills green → orange → red as you spend; today's total in the centre |
| **Rectangular** | Today + Month amounts with an optional budget progress bar |
| **Inline** | Single-line today's total above the clock |

### Control Center (iOS 18+)
Add the **SmartSpend → Add Expense** button to your Control Center or Lock Screen. Tap it from anywhere — lock screen, notification centre — to jump straight to the Add Expense screen with one tap.

## 🚀 Getting Started

1.  **Clone the repo**:
    ```bash
    git clone https://github.com/JohnUfo/SmartSpend.git
    ```
2.  **Open in Xcode**:
    Double-click `SmartSpend.xcodeproj`.
3.  **Configure App Group** *(required for widgets)*:
    - Select the **SmartSpend** target → Signing & Capabilities → App Groups → `group.muydinov.SmartSpend`
    - Do the same for the **Widget** extension target
4.  **Run**:
    Select your simulator or device and hit **Play** (Cmd+R).
    *Requires Xcode 16.0+ and iOS 17.0+*

## 🛠 Tech Stack

*   **Language**: Swift 6
*   **UI Framework**: SwiftUI
*   **Architecture**: MVVM
*   **Charts**: Apple Swift Charts
*   **Storage**: UserDefaults / JSON Persistence (Local & Private, shared via App Groups)
*   **Widgets**: WidgetKit — home screen, lock screen, and Control Center
*   **Intents**: AppIntents — interactive widget buttons (iOS 17+), Control Center action (iOS 18+)

## 📞 Support

Need help or have suggestions?
- **AI Accountant Chat**: Chat with our built-in AI assistant directly in the app.
- **Email**: tursunov.umidjon.uz@gmail.com

---
*Built with ❤️ for a smarter financial future*
