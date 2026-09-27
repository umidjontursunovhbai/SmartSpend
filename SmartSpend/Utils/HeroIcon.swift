import SwiftUI

struct HeroIcon: View {
    let name: String
    var size: CGFloat = 22

    init(_ name: String, size: CGFloat = 22) {
        self.name = HeroIcon.resolvedName(name)
        self.size = size
    }

    init(systemName: String, size: CGFloat = 22) {
        self.name = HeroIcon.resolvedName(systemName)
        self.size = size
    }

    var body: some View {
        Image("hero-\(name)")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }

    static func resolvedName(_ iconName: String) -> String {
        if canonicalNames.contains(iconName) {
            return iconName
        }

        let systemName = iconName
        switch systemName {
        case "house.fill", "house":
            return "home"
        case "list.bullet.rectangle", "list.bullet", "line.3.horizontal":
            return "list-bullet"
        case "chart.bar.fill", "chart.bar", "chart.bar.doc.horizontal":
            return "chart-bar"
        case "repeat":
            return "arrow-path"
        case "gear", "gearshape.fill":
            return "cog-6-tooth"
        case "plus", "plus.circle", "plus.circle.fill":
            return "plus"
        case "line.3.horizontal.decrease.circle", "line.3.horizontal.decrease.circle.fill":
            return "funnel"
        case "tray":
            return "archive-box"
        case "arrow.left.and.right":
            return "arrows-right-left"
        case "arrow.counterclockwise":
            return "arrow-path"
        case "arrow.right":
            return "arrow-right"
        case "arrow.up.right":
            return "arrow-trending-up"
        case "arrow.down.right":
            return "arrow-trending-down"
        case "checkmark.circle", "checkmark.circle.fill":
            return "check-circle"
        case "checkmark":
            return "check"
        case "circle":
            return "check-circle"
        case "trash", "trash.fill":
            return "trash"
        case "calendar", "calendar.badge.plus", "calendar.badge.clock", "calendar.badge.minus", "calendar.badge.exclamationmark":
            return "calendar"
        case "calendar.badge.checkmark":
            return "calendar-days"
        case "chevron.right":
            return "chevron-right"
        case "chevron.left":
            return "chevron-left"
        case "magnifyingglass":
            return "magnifying-glass"
        case "wallet.pass", "wallet.pass.fill":
            return "wallet"
        case "tag", "tag.fill", "pawprint.fill":
            return "tag"
        case "creditcard.fill", "creditcard":
            return "credit-card"
        case "envelope.fill", "envelope":
            return "envelope"
        case "hand.raised.fill", "hand.raised":
            return "hand-raised"
        case "square.and.arrow.down", "doc.badge.plus":
            return "arrow-down-tray"
        case "square.and.arrow.up":
            return "arrow-up-tray"
        case "archivebox", "archivebox.fill":
            return "archive-box"
        case "target":
            return "flag"
        case "chart.pie", "chart.pie.fill":
            return "chart-pie"
        case "dollarsign.circle.fill", "dollarsign.circle":
            return "banknotes"
        case "lightbulb.fill":
            return "sparkles"
        case "delete.left":
            return "x-mark"
        case "repeat.circle":
            return "arrow-path"
        case "doc.text", "doc.text.magnifyingglass":
            return "document-text"
        case "pencil":
            return "pencil"
        case "cart.fill", "cart":
            return "shopping-cart"
        case "bag.fill", "bag":
            return "shopping-bag"
        case "banknote.fill", "banknote":
            return "banknotes"
        case "building.2.fill", "building.2":
            return "building-office"
        case "storefront.fill", "storefront":
            return "building-storefront"
        case "car.fill", "car", "bus.fill", "bus", "tram.fill", "airplane":
            return "truck"
        case "fork.knife":
            return "shopping-cart"
        case "cup.and.saucer.fill", "wineglass.fill":
            return "beaker"
        case "birthday.cake.fill":
            return "cake"
        case "heart.fill", "cross.case.fill", "pills.fill", "stethoscope":
            return "heart"
        case "book.fill", "graduationcap.fill", "academic.cap.fill", "backpack.fill":
            return "book-open"
        case "gamecontroller.fill", "tv.fill", "headphones":
            return "sparkles"
        case "music.note":
            return "musical-note"
        case "sportscourt.fill", "figure.run", "dumbbell.fill", "bicycle":
            return "bolt"
        case "gift.fill":
            return "gift"
        case "sparkles":
            return "sparkles"
        case "star.fill":
            return "star"
        case "bolt.fill":
            return "bolt"
        case "wrench.fill", "hammer.fill":
            return "wrench"
        case "paintbrush.fill":
            return "paint-brush"
        case "scissors":
            return "scissors"
        case "phone.fill":
            return "phone"
        case "wifi", "network":
            return "wifi"
        case "leaf.fill", "drop.fill":
            return "beaker"
        case "flame.fill":
            return "fire"
        case "theatermasks.fill", "ticket.fill":
            return "ticket"
        case "eye":
            return "eye"
        case "info.circle", "info.circle.fill":
            return "information-circle"
        default:
            return "tag"
        }
    }

    private static let canonicalNames: Set<String> = [
        "academic-cap", "adjustments-horizontal", "archive-box-arrow-down",
        "archive-box-x-mark", "archive-box", "arrow-down-tray", "arrow-left",
        "arrow-path", "arrow-right", "arrow-trending-down", "arrow-trending-up",
        "arrow-up-tray", "arrows-right-left", "banknotes", "beaker", "bolt",
        "book-open", "briefcase", "building-library", "building-office",
        "building-storefront", "cake", "calendar-date-range", "calendar-days",
        "calendar", "chart-bar", "chart-pie", "check-badge", "check-circle",
        "check", "chevron-left", "chevron-right", "cog-6-tooth", "credit-card",
        "document-plus", "document-text", "envelope", "eye", "fire", "flag",
        "funnel", "gift", "hand-raised", "heart", "home", "information-circle",
        "list-bullet", "magnifying-glass", "musical-note", "paint-brush", "pencil",
        "phone", "plus", "scissors", "shopping-bag", "shopping-cart", "sparkles",
        "star", "tag", "ticket", "trash", "truck", "wallet", "wifi",
        "wrench", "x-mark"
    ]
}

struct HeroIconLabel: View {
    let title: String
    let systemName: String
    var iconSize: CGFloat = 21
    var spacing: CGFloat = 8

    var body: some View {
        HStack(spacing: spacing) {
            HeroIcon(systemName: systemName, size: iconSize)
            Text(title)
        }
    }
}
