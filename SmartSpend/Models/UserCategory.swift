import Foundation
import SwiftUI

struct UserCategory: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var iconSystemName: String
    var colorName: String
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, iconSystemName: String = "tag", colorName: String = "systemBlue") {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.iconSystemName = iconSystemName
        self.colorName = colorName
        self.createdAt = Date()
    }

    static func imported(name: String) -> UserCategory {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return UserCategory(
            name: trimmedName,
            iconSystemName: defaultIconName(for: trimmedName),
            colorName: defaultColorName(for: trimmedName)
        )
    }
    
    static func createDefault() -> UserCategory {
        return UserCategory(name: "Other", iconSystemName: "tag", colorName: "systemGray")
    }
}

extension UserCategory {
    static func defaultIconName(for categoryName: String) -> String {
        let normalized = categoryName.lowercased()

        if normalized.contains("food") || normalized.contains("restaurant") || normalized.contains("dining") || normalized.contains("meal") || normalized.contains("grocery") {
            return "shopping-cart"
        }
        if normalized.contains("coffee") || normalized.contains("cafe") || normalized.contains("tea") {
            return "beaker"
        }
        if normalized.contains("transport") || normalized.contains("taxi") || normalized.contains("uber") || normalized.contains("fuel") || normalized.contains("gas") || normalized.contains("car") {
            return "truck"
        }
        if normalized.contains("home") || normalized.contains("rent") || normalized.contains("house") || normalized.contains("utilities") {
            return "home"
        }
        if normalized.contains("health") || normalized.contains("medical") || normalized.contains("doctor") || normalized.contains("pharmacy") {
            return "heart"
        }
        if normalized.contains("education") || normalized.contains("school") || normalized.contains("book") || normalized.contains("course") {
            return "book-open"
        }
        if normalized.contains("shopping") || normalized.contains("clothes") || normalized.contains("store") || normalized.contains("market") {
            return "shopping-bag"
        }
        if normalized.contains("entertainment") || normalized.contains("movie") || normalized.contains("game") || normalized.contains("music") {
            return "ticket"
        }
        if normalized.contains("travel") || normalized.contains("flight") || normalized.contains("hotel") || normalized.contains("trip") {
            return "briefcase"
        }
        if normalized.contains("gift") || normalized.contains("donation") {
            return "gift"
        }
        if normalized.contains("salary") || normalized.contains("income") || normalized.contains("pay") {
            return "banknotes"
        }
        if normalized.contains("other") || normalized.contains("misc") || normalized.contains("unknown") {
            return "tag"
        }

        return "tag"
    }

    static func defaultColorName(for categoryName: String) -> String {
        let normalized = categoryName.lowercased()

        if normalized.contains("food") || normalized.contains("restaurant") || normalized.contains("dining") || normalized.contains("meal") || normalized.contains("grocery") {
            return "systemOrange"
        }
        if normalized.contains("coffee") || normalized.contains("cafe") || normalized.contains("tea") {
            return "systemBrown"
        }
        if normalized.contains("transport") || normalized.contains("taxi") || normalized.contains("uber") || normalized.contains("fuel") || normalized.contains("gas") || normalized.contains("car") {
            return "systemBlue"
        }
        if normalized.contains("home") || normalized.contains("rent") || normalized.contains("house") || normalized.contains("utilities") {
            return "systemIndigo"
        }
        if normalized.contains("health") || normalized.contains("medical") || normalized.contains("doctor") || normalized.contains("pharmacy") {
            return "systemRed"
        }
        if normalized.contains("education") || normalized.contains("school") || normalized.contains("book") || normalized.contains("course") {
            return "systemPurple"
        }
        if normalized.contains("shopping") || normalized.contains("clothes") || normalized.contains("store") || normalized.contains("market") {
            return "systemPink"
        }
        if normalized.contains("entertainment") || normalized.contains("movie") || normalized.contains("game") || normalized.contains("music") {
            return "systemMint"
        }
        if normalized.contains("travel") || normalized.contains("flight") || normalized.contains("hotel") || normalized.contains("trip") {
            return "systemCyan"
        }
        if normalized.contains("gift") || normalized.contains("donation") {
            return "systemGreen"
        }
        if normalized.contains("salary") || normalized.contains("income") || normalized.contains("pay") {
            return "systemGreen"
        }
        if normalized.contains("other") || normalized.contains("misc") || normalized.contains("unknown") {
            return "systemGray"
        }

        let colors = presetColors.filter { $0 != "systemGray" }
        let unicodeTotal = normalized.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return colors[unicodeTotal % colors.count]
    }

    var color: Color {
        switch colorName {
        case "systemRed": return Color(.systemRed)
        case "systemOrange": return Color(.systemOrange)
        case "systemYellow": return Color(.systemYellow)
        case "systemGreen": return Color(.systemGreen)
        case "systemMint": return Color(.systemMint)
        case "systemTeal": return Color(.systemTeal)
        case "systemCyan": return Color(.systemCyan)
        case "systemBlue": return Color(.systemBlue)
        case "systemIndigo": return Color(.systemIndigo)
        case "systemPurple": return Color(.systemPurple)
        case "systemPink": return Color(.systemPink)
        case "systemBrown": return Color(.systemBrown)
        case "systemGray": return Color(.systemGray)
        default: return Color(.systemBlue)
        }
    }
    
    static let presetColors: [String] = [
        "systemRed", "systemOrange", "systemYellow", "systemGreen", "systemMint",
        "systemTeal", "systemCyan", "systemBlue", "systemIndigo", "systemPurple",
        "systemPink", "systemBrown", "systemGray"
    ]

    static let presetIcons: [String] = [
        "tag", "shopping-cart", "shopping-bag", "credit-card", "banknotes",
        "home", "truck", "building-storefront", "briefcase", "academic-cap",
        "book-open", "pencil", "musical-note", "ticket", "sparkles", "heart",
        "beaker", "bolt", "fire", "gift", "cake", "wrench", "paint-brush",
        "scissors", "phone", "envelope", "wifi", "flag", "star", "calendar",
        "document-text"
    ]
}
