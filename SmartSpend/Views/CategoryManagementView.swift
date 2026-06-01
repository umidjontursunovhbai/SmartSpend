import SwiftUI

struct CategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared

    @State private var editorRoute: CategoryEditorRoute?

    var body: some View {
        NavigationStack {
            List {
                if dataManager.userCategories.isEmpty {
                    Text("No categories yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dataManager.userCategories) { category in
                        HStack(spacing: 12) {
                            Image(systemName: category.iconSystemName)
                                .foregroundStyle(category.color)
                                .frame(width: 28)
                            Text(category.name)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editorRoute = .edit(category)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                dataManager.deleteUserCategory(category)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                editorRoute = .edit(category)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("categories".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editorRoute = .add
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editorRoute) { route in
                CategoryEditorView(category: route.category)
                    .presentationDetents([.large])
            }
        }
    }
}

private enum CategoryEditorRoute: Identifiable {
    case add
    case edit(UserCategory)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let category):
            return category.id.uuidString
        }
    }

    var category: UserCategory? {
        switch self {
        case .add:
            return nil
        case .edit(let category):
            return category
        }
    }
}

// MARK: - Editor

struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared

    let category: UserCategory?

    @State private var name: String
    @State private var iconSystemName: String
    @State private var selectedColorName: String
    @State private var showValidationError = false

    private let availableIcons = [
        "tag.fill", "cart.fill", "bag.fill", "creditcard.fill", "banknote.fill",
        "house.fill", "car.fill", "bus.fill", "tram.fill", "airplane",
        "fork.knife", "cup.and.saucer.fill", "wineglass.fill", "birthday.cake.fill",
        "heart.fill", "cross.case.fill", "pills.fill", "stethoscope",
        "book.fill", "graduationcap.fill", "pencil", "backpack.fill",
        "gamecontroller.fill", "tv.fill", "headphones", "music.note",
        "sportscourt.fill", "figure.run", "dumbbell.fill", "bicycle",
        "gift.fill", "sparkles", "star.fill", "bolt.fill",
        "wrench.fill", "hammer.fill", "paintbrush.fill", "scissors",
        "phone.fill", "envelope.fill", "wifi", "network",
        "pawprint.fill", "leaf.fill", "drop.fill", "flame.fill",
        "building.2.fill", "storefront.fill", "theatermasks.fill", "ticket.fill"
    ]

    init(category: UserCategory?) {
        self.category = category
        _name             = State(initialValue: category?.name ?? "")
        _iconSystemName   = State(initialValue: category?.iconSystemName ?? "tag.fill")
        _selectedColorName = State(initialValue: category?.colorName ?? "systemBlue")
    }

    private var selectedColor: Color { color(for: selectedColorName) }
    private var isEditing: Bool { category != nil }

    var body: some View {
        NavigationStack {
            Form {
                // Name
                Section {
                    TextField("Category name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                // Icon
                Section("Icon") {
                    iconGrid
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }

                // Color
                Section("Color") {
                    colorGrid
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "save".localized : "add".localized) {
                        saveCategory()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Invalid Name", isPresented: $showValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a unique category name.")
            }
        }
    }

    // MARK: - Grids

    private var iconGrid: some View {
        let columns = [GridItem(.adaptive(minimum: 44), spacing: 8)]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(availableIcons, id: \.self) { iconName in
                let isSelected = iconSystemName == iconName
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? selectedColor : .primary)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? selectedColor.opacity(0.15) : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? selectedColor : Color.clear, lineWidth: 1.5)
                    )
                    .onTapGesture { iconSystemName = iconName }
            }
        }
    }

    private var colorGrid: some View {
        let columns = [GridItem(.adaptive(minimum: 36), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(UserCategory.presetColors, id: \.self) { colorName in
                let isSelected = selectedColorName == colorName
                Circle()
                    .fill(color(for: colorName))
                    .frame(width: 34, height: 34)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    .onTapGesture { selectedColorName = colorName }
            }
        }
    }

    // MARK: - Helpers

    private func color(for name: String) -> Color {
        switch name {
        case "systemRed":    return Color(.systemRed)
        case "systemOrange": return Color(.systemOrange)
        case "systemYellow": return Color(.systemYellow)
        case "systemGreen":  return Color(.systemGreen)
        case "systemMint":   return Color(.systemMint)
        case "systemTeal":   return Color(.systemTeal)
        case "systemCyan":   return Color(.systemCyan)
        case "systemBlue":   return Color(.systemBlue)
        case "systemIndigo": return Color(.systemIndigo)
        case "systemPurple": return Color(.systemPurple)
        case "systemPink":   return Color(.systemPink)
        case "systemBrown":  return Color(.systemBrown)
        case "systemGray":   return Color(.systemGray)
        default:             return Color(.systemBlue)
        }
    }

    private func saveCategory() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let isDuplicate = dataManager.userCategories.contains {
            $0.name.lowercased() == trimmed.lowercased() && $0.id != category?.id
        }
        guard !isDuplicate else { showValidationError = true; return }

        if var updated = category {
            updated.name = trimmed
            updated.iconSystemName = iconSystemName
            updated.colorName = selectedColorName
            dataManager.updateUserCategory(updated)
        } else {
            let new = UserCategory(name: trimmed, iconSystemName: iconSystemName, colorName: selectedColorName)
            dataManager.addUserCategory(new)
        }
        dismiss()
    }
}

#Preview {
    CategoryManagementView()
}
