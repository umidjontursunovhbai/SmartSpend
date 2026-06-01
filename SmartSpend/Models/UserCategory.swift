import Foundation
import SwiftUI

struct UserCategory: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var iconSystemName: String
    var colorName: String
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, iconSystemName: String = "tag.fill", colorName: String = "systemBlue") {
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
        return UserCategory(name: "Other", iconSystemName: "tag.fill", colorName: "systemGray")
    }
}

extension UserCategory {
    static func defaultIconName(for categoryName: String) -> String {
        let normalized = categoryName.lowercased()

        if normalized.contains("food") || normalized.contains("restaurant") || normalized.contains("dining") || normalized.contains("meal") || normalized.contains("grocery") {
            return "fork.knife"
        }
        if normalized.contains("coffee") || normalized.contains("cafe") || normalized.contains("tea") {
            return "cup.and.saucer.fill"
        }
        if normalized.contains("transport") || normalized.contains("taxi") || normalized.contains("uber") || normalized.contains("fuel") || normalized.contains("gas") || normalized.contains("car") {
            return "car.fill"
        }
        if normalized.contains("home") || normalized.contains("rent") || normalized.contains("house") || normalized.contains("utilities") {
            return "house.fill"
        }
        if normalized.contains("health") || normalized.contains("medical") || normalized.contains("doctor") || normalized.contains("pharmacy") {
            return "cross.case.fill"
        }
        if normalized.contains("education") || normalized.contains("school") || normalized.contains("book") || normalized.contains("course") {
            return "book.fill"
        }
        if normalized.contains("shopping") || normalized.contains("clothes") || normalized.contains("store") || normalized.contains("market") {
            return "bag.fill"
        }
        if normalized.contains("entertainment") || normalized.contains("movie") || normalized.contains("game") || normalized.contains("music") {
            return "gamecontroller.fill"
        }
        if normalized.contains("travel") || normalized.contains("flight") || normalized.contains("hotel") || normalized.contains("trip") {
            return "airplane"
        }
        if normalized.contains("gift") || normalized.contains("donation") {
            return "gift.fill"
        }
        if normalized.contains("salary") || normalized.contains("income") || normalized.contains("pay") {
            return "banknote.fill"
        }
        if normalized.contains("other") || normalized.contains("misc") || normalized.contains("unknown") {
            return "tag.fill"
        }

        return "tag.fill"
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
}
