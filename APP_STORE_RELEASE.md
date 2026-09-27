# SmartSpend App Store release preparation

Audit date: September 27, 2026. This is a preparation checklist, not proof of App Store approval or publication.

## Verified locally

- Bundle ID: `com.tursunov.SmartSpend`; widget: `com.tursunov.SmartSpend.Widget`.
- Version in the current project: `2.0 (1)`. Check App Store Connect before deciding whether build `1` is reusable.
- Minimum OS: iOS 18.5. The project currently supports iPhone **and iPad**; both need release QA and appropriate screenshots.
- Xcode 27 Release archive builds successfully with the app and widget. The archive is development-signed, not yet an App Store IPA.
- The app and widget bundle their privacy manifests. The 1024×1024 app icons have no alpha channel.
- The app uses local storage/App Group and has no active CloudKit sync, in-app account, ads, or third-party analytics in this build.
- An in-app privacy policy and support email are reachable from Settings.

## Blockers before upload

1. The intended paid team is `HUMBLE BEE AI, MCHJ` (`94MJH9FHS9`), but a local archive check with that team failed: the current `group.com.tursunov.SmartSpend` App Group is unavailable to it. The project's current personal team (`4R72PTT5ZJ`) can build an archive but cannot create App Store distribution profiles. Do **not** silently replace the App Group: the current iPhone build stores records there, so changing it can hide existing records. First back up/export data, determine whether the original group can be moved or a new group is necessary, and test migration with a disposable data copy. Then configure app and widget identifiers/entitlements/profiles under the paid team, rebuild, export an `app-store-connect` IPA, and validate it. No App Store IPA exists yet.
2. Publish the prepared `docs/` site through GitHub Pages and verify both public links return HTTP 200. The repository is public, but GitHub Pages was not enabled during this audit. After publishing from `main` / `/docs`, the expected URLs are `https://umidjontursunovhbai.github.io/SmartSpend/privacy.html` and `https://umidjontursunovhbai.github.io/SmartSpend/support.html`. Do not enter them in App Store Connect before checking the live pages.
3. Confirm the app record, bundle ID, version/build uniqueness, distribution agreements, and appropriate account roles in App Store Connect.
   A public App Store listing already uses the name **Smartspend**; treat `SmartSpend` as provisional until App Store Connect confirms name availability for the chosen localization. Select a distinct name if it is unavailable; do not imitate another app's branding.
4. Capture screenshots of the **release build with synthetic data**, not private expense records. At least one screenshot is required; provide the device classes and localizations App Store Connect requests for this iPhone+iPad app. Visually test empty, populated, import/export, budgets, recurring expenses, widget, and narrow/iPad layouts.
5. Complete App Store Connect fields: app name, primary language/category, age-rating questionnaire, content rights, pricing/availability, Digital Services Act status where applicable, app privacy answers, privacy policy URL, support URL, description, keywords, copyright, and App Review contact/notes. Complete export-compliance questions if requested. Review these answers against the final shipped binary.

## Suggested English metadata draft

Name: `SmartSpend` (provisional; App Store Connect availability check required)

Subtitle: `Track spending with clarity`

Primary category: `Finance` (confirm in App Store Connect)

Keywords: `expense tracker,budget,spending,recurring bills,money,csv`

Description:

> SmartSpend helps you record expenses, see where your money goes, and plan around monthly income.
>
> Add expenses and organize them by category. Set category budgets and spending goals. See this month's spending, recent expenses, and upcoming recurring bills at a glance. Import expenses from a CSV file or export a copy of your records when you need one.
>
> No account is required. In the current version, SmartSpend records are stored on your device and can be shared with its iOS widget.

Do not claim bank sync, live account balances, AI advice, or cloud sync in the listing; the current build does not provide those features.

## Submission boundary

Creating a local archive is not the same as exporting a distribution-signed IPA. Export is not upload. Upload/processing is not App Review submission. Approval is not public release. Record evidence for each step separately.

References: [Apple upload requirements](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds), [required App Store properties](https://developer.apple.com/help/app-store-connect/reference/app-information/required-localizable-and-editable-properties), [privacy declarations](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy), and [screenshot requirements](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/).
