# SmartSpend - Deployment Guide

> Historical guide: the bundle ID, version, screenshots, and feature list below are outdated. For the current App Store preparation state and verified release steps, use [APP_STORE_RELEASE.md](APP_STORE_RELEASE.md). Do not change the existing bundle ID or submit using the example metadata below.

This guide will help you deploy SmartSpend to GitHub and prepare it for distribution.

## 🚀 GitHub Setup

### 1. Initialize Git Repository
```bash
# Navigate to your project directory
cd /Users/umidjontursunov/Desktop/SmartSpend

# Initialize git repository
git init

# Add all files
git add .

# Make initial commit
git commit -m "Initial commit: SmartSpend iOS Expense Tracker"
```

### 2. Create GitHub Repository
1. Go to [GitHub.com](https://github.com)
2. Click "New repository"
3. Name it `SmartSpend`
4. Make it **Public** (for open source)
5. **Don't** initialize with README (we already have one)
6. Click "Create repository"

### 3. Push to GitHub
```bash
# Add remote origin (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/SmartSpend.git

# Push to main branch
git branch -M main
git push -u origin main
```

## 📱 App Store Preparation

### 1. Update Bundle Identifier
- Open `SmartSpend.xcodeproj` in Xcode
- Select the project in the navigator
- Go to "Signing & Capabilities"
- Update Bundle Identifier to: `com.yourusername.SmartSpend`

### 2. Update App Information
- Open `Info.plist`
- Update the following fields:
  - `CFBundleDisplayName`: SmartSpend
  - `CFBundleIdentifier`: com.yourusername.SmartSpend
  - `CFBundleVersion`: 2.0.0
  - `CFBundleShortVersionString`: 2.0.0

### 3. App Store Connect Setup
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create a new app
3. Fill in app information:
   - **Name**: SmartSpend
   - **Bundle ID**: com.yourusername.SmartSpend
   - **SKU**: SmartSpend2025
   - **User Access**: Full Access

### 4. App Store Metadata
Prepare the following for App Store submission:

#### App Description
```
SmartSpend - Intelligent Expense Tracker

Track your expenses intelligently with SmartSpend, the iOS app that learns your spending patterns and makes expense management effortless.

KEY FEATURES:
• Smart Learning System - Automatically suggests amounts and categories
• Multi-Currency Support - USD, UZS, RUBL with proper formatting
• CSV Import - Import expenses from Notion, Excel, or any CSV file
• Advanced Analytics - Detailed spending insights and trends
• Recurring Expenses - Automated tracking for subscriptions and bills
• Budget Management - Set limits and track spending goals
• Monthly Salary System - Track different salaries per month
• 30-Day Recovery - Soft-delete with countdown timer

Perfect for anyone who wants to take control of their finances with an intelligent, user-friendly expense tracker.
```

#### Keywords
```
expense,tracker,budget,money,finance,spending,smart,learning,analytics,recurring,import,csv,notion,currency,uzs,usd,rubl
```

#### Screenshots
Prepare screenshots for:
- iPhone 6.7" (iPhone 15 Pro Max)
- iPhone 6.5" (iPhone 14 Plus)
- iPhone 5.5" (iPhone 8 Plus)

## 🔧 Build Configuration

### 1. Archive for App Store
```bash
# Clean build folder
xcodebuild clean -project SmartSpend.xcodeproj -scheme SmartSpend

# Archive the project
xcodebuild archive -project SmartSpend.xcodeproj -scheme SmartSpend -archivePath SmartSpend.xcarchive
```

### 2. Export IPA
1. Open Xcode
2. Go to Window → Organizer
3. Select your archive
4. Click "Distribute App"
5. Choose "App Store Connect"
6. Follow the export process

## 📋 Pre-Release Checklist

- [ ] All features tested and working
- [ ] App icon properly set
- [ ] Bundle identifier updated
- [ ] Version numbers set correctly
- [ ] README.md updated
- [ ] LICENSE file included
- [ ] .gitignore configured
- [ ] Code reviewed and cleaned
- [ ] App Store metadata prepared
- [ ] Screenshots captured
- [ ] Archive created successfully
- [ ] IPA exported and validated

## 🎯 Release Notes

### Version 2.0.0
- Enhanced budget management with interactive overview
- Dynamic time-based filtering (All Time, This Month, Last Month, Custom Month)
- Improved UI/UX with iOS 17+ compatibility
- Enhanced gesture handling and scrolling on physical devices
- Better search functionality with keyboard dismissal
- Streamlined analytics with improved chart visualization
- Immediate budget updates without page navigation
- Spending goal completion alerts
- Enhanced material design with improved visual depth
- Performance optimizations and better error handling

### Version 1.0.0
- Initial release of SmartSpend
- Smart learning system with 3-month pattern recognition
- Multi-currency support (USD, UZS, RUBL)
- CSV import functionality with automatic category mapping
- Advanced analytics and spending insights
- Recurring expense management
- Monthly salary tracking system
- 30-day soft-delete recovery
- iOS 18.5+ compatibility
- Dark mode support

## 🆘 Troubleshooting

### Common Issues

#### Build Errors
- Clean build folder: `Product → Clean Build Folder`
- Reset package caches: `File → Packages → Reset Package Caches`

#### Signing Issues
- Check Apple Developer account status
- Verify provisioning profiles
- Update bundle identifier if needed

#### Import Issues
- Ensure CSV file is properly formatted
- Check console logs for detailed error messages
- Verify category mappings in DataImporter.swift

## 📞 Support

For deployment issues:
1. Check Xcode console for error messages
2. Verify all configuration settings
3. Ensure Apple Developer account is active
4. Contact Apple Developer Support if needed

---

**Ready to deploy SmartSpend! 🚀**
