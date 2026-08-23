import Foundation

struct CurrencyFormatter {

    // MARK: - Cached formatters
    //
    // NumberFormatter is expensive to allocate (locale lookups, ICU setup).
    // CurrencyFormatter.format is called for every list row on every redraw,
    // so we cache one formatter per (currency, style) and reuse it.
    // All access is funneled through a serial queue because NumberFormatter
    // is not safe to mutate from multiple threads concurrently.

    private static let cacheQueue = DispatchQueue(label: "com.tursunov.SmartSpend.currencyformatter")
    private static var fullCache: [String: NumberFormatter] = [:]
    private static var compactCache: [String: NumberFormatter] = [:]

    private static let percentFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 1
        return f
    }()

    private static func fullFormatter(for currency: Currency) -> NumberFormatter {
        cacheQueue.sync {
            if let f = fullCache[currency.rawValue] { return f }
            let f = NumberFormatter()
            f.numberStyle = .currency
            f.currencyCode = currency.rawValue
            f.locale = currency.locale
            f.minimumFractionDigits = 2
            f.maximumFractionDigits = 2
            fullCache[currency.rawValue] = f
            return f
        }
    }

    private static func compactFormatter(for currency: Currency) -> NumberFormatter {
        cacheQueue.sync {
            if let f = compactCache[currency.rawValue] { return f }
            let f = NumberFormatter()
            f.numberStyle = .currency
            f.currencyCode = currency.rawValue
            f.locale = currency.locale
            f.maximumFractionDigits = 0
            compactCache[currency.rawValue] = f
            return f
        }
    }

    // MARK: - Public API

    static func format(_ amount: Double, currency: Currency) -> String {
        if let formatted = fullFormatter(for: currency).string(from: NSNumber(value: amount)) {
            return formatted
        }
        return "\(amount) \(currency.symbol)"
    }

    static func formatCompact(_ amount: Double, currency: Currency) -> String {
        if let formatted = compactFormatter(for: currency).string(from: NSNumber(value: amount)) {
            return formatted
        }
        return "\(Int(amount)) \(currency.symbol)"
    }

    static func formatChartCompact(_ amount: Double, currency: Currency) -> String {
        let absolute = abs(amount)
        let sign = amount < 0 ? "-" : ""
        let suffix: String
        let value: Double

        switch absolute {
        case 1_000_000_000...:
            value = absolute / 1_000_000_000
            suffix = "B"
        case 1_000_000...:
            value = absolute / 1_000_000
            suffix = "M"
        case 1_000...:
            value = absolute / 1_000
            suffix = "K"
        default:
            value = absolute
            suffix = ""
        }

        let decimals = value >= 10 || value.rounded() == value ? 0 : 1
        let number = String(format: "%.\(decimals)f", value)

        switch currency {
        case .uzs:
            return "\(sign)\(number)\(suffix) so'm"
        default:
            return "\(sign)\(currency.rawValue) \(number)\(suffix)"
        }
    }

    static func formatPercentage(_ value: Double) -> String {
        percentFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value * 100))%"
    }

    static func formatWithSymbol(_ amount: Double, currency: Currency) -> String {
        format(amount, currency: currency)
    }
}
