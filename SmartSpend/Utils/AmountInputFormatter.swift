import Foundation

enum AmountInputFormatter {
    static func formatEditingText(_ text: String, maxFractionDigits: Int = 2) -> String {
        let normalized = normalizedNumericText(text, maxFractionDigits: maxFractionDigits)
        guard !normalized.isEmpty else { return "" }

        let parts = normalized.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let rawIntegerPart = parts.first.map(String.init) ?? ""
        let integerPart = rawIntegerPart.isEmpty ? "0" : rawIntegerPart
        let groupedInteger = groupedDigits(integerPart)

        if normalized.contains(".") {
            let fractionPart = parts.count > 1 ? String(parts[1]) : ""
            return "\(groupedInteger).\(fractionPart)"
        }

        return groupedInteger
    }

    static func formatValue(_ value: Double, maxFractionDigits: Int = 2) -> String {
        guard value.isFinite else { return "" }

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maxFractionDigits

        return formatter.string(from: NSNumber(value: value)) ?? ""
    }

    static func parse(_ text: String) -> Double? {
        let normalized = normalizedNumericText(text, maxFractionDigits: Int.max)
        guard !normalized.isEmpty, normalized != "." else { return nil }
        return Double(normalized)
    }

    private static func normalizedNumericText(_ text: String, maxFractionDigits: Int) -> String {
        var result = ""
        var hasDecimalSeparator = false
        var fractionDigits = 0

        for character in text {
            if character.isNumber {
                if hasDecimalSeparator {
                    guard fractionDigits < maxFractionDigits else { continue }
                    fractionDigits += 1
                }
                result.append(character)
            } else if character == "." && !hasDecimalSeparator {
                hasDecimalSeparator = true
                result.append(character)
            }
        }

        guard !result.isEmpty else { return "" }

        if let decimalIndex = result.firstIndex(of: ".") {
            let integerPart = String(result[..<decimalIndex])
            let fractionPart = String(result[result.index(after: decimalIndex)...])
            return "\(trimLeadingZeros(integerPart)).\(fractionPart)"
        }

        return trimLeadingZeros(result)
    }

    private static func trimLeadingZeros(_ text: String) -> String {
        let trimmed = text.drop { $0 == "0" }
        return trimmed.isEmpty ? "0" : String(trimmed)
    }

    private static func groupedDigits(_ digits: String) -> String {
        var grouped = ""

        for (offset, character) in digits.reversed().enumerated() {
            if offset > 0 && offset % 3 == 0 {
                grouped.append(",")
            }
            grouped.append(character)
        }

        return String(grouped.reversed())
    }
}
