import SwiftUI

struct ShoppingListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shoppingList: [String: [String]] = [:]
    @State private var checkedItems: Set<String> = []
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if shoppingList.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                        
                        // Progress Section
                        if !shoppingList.isEmpty {
                            progressSection
                        }
                        
                        // Shopping List Sections
                        ForEach(Array(shoppingList.keys.sorted()), id: \.self) { category in
                            if let items = shoppingList[category], !items.isEmpty {
                                ShoppingCategorySection(
                                    category: category,
                                    items: items,
                                    checkedItems: $checkedItems
                                )
                            }
                        }
                        
                        // Bottom spacing
                        Color.clear.frame(height: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
        }
        .navigationTitle("Shopping List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear All") {
                    checkedItems.removeAll()
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.green)
                .disabled(checkedItems.isEmpty)
            }
        }
        .onAppear {
            loadShoppingList()
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Image(systemName: "cart.badge.questionmark")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("No Shopping List Available")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Generate a meal plan first to create your shopping list.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button("Generate Meal Plan") {
                dismiss()
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.green, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "cart.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                
                Text("Weekly Shopping List")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Spacer()
                
                // Total items badge
                HStack {
                    Image(systemName: "list.bullet")
                        .font(.caption)
                    Text("\(totalItemsCount) items")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.green)
                )
            }
            
            Text("Everything you need for your weekly meal plan")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Shopping Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(checkedItems.count)/\(totalItemsCount)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 12)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressPercentage, height: 12)
                        .clipShape(Capsule())
                        .animation(.spring(response: 0.5), value: progressPercentage)
                }
            }
            .frame(height: 12)
            
            Text("\(Int(progressPercentage * 100))% Complete")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Computed Properties
    private var totalItemsCount: Int {
        shoppingList.values.flatMap { $0 }.count
    }
    
    private var progressPercentage: Double {
        guard totalItemsCount > 0 else { return 0 }
        return Double(checkedItems.count) / Double(totalItemsCount)
    }
    
    // MARK: - Helper Functions
    private func loadShoppingList() {
        guard let shoppingListString = UserDefaults.standard.string(forKey: "weeklyShoppingList"),
              let data = shoppingListString.data(using: .utf8),
              let decodedList = try? JSONSerialization.jsonObject(with: data) as? [String: [String]] else {
            return
        }
        
        shoppingList = decodedList
    }
}

// MARK: - Supporting Views

struct ShoppingCategorySection: View {
    let category: String
    let items: [String]
    @Binding var checkedItems: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category header
            HStack {
                Image(systemName: categoryIcon)
                    .font(.title3)
                    .foregroundColor(categoryColor)
                
                Text(category)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(items.count) items")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(categoryColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(categoryColor.opacity(0.1))
                    )
            }
            
            // Items list
            VStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    ShoppingItemRow(
                        item: item,
                        isChecked: checkedItems.contains(item),
                        onToggle: {
                            if checkedItems.contains(item) {
                                checkedItems.remove(item)
                            } else {
                                checkedItems.insert(item)
                            }
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    private var categoryIcon: String {
        switch category.lowercased() {
        case "proteins", "protein":
            return "fish.fill"
        case "vegetables", "produce":
            return "leaf.fill"
        case "dairy":
            return "drop.fill"
        case "pantry items", "pantry":
            return "cabinet.fill"
        case "herbs & spices", "spices":
            return "sparkles"
        default:
            return "bag.fill"
        }
    }
    
    private var categoryColor: Color {
        switch category.lowercased() {
        case "proteins", "protein":
            return .red
        case "vegetables", "produce":
            return .green
        case "dairy":
            return .blue
        case "pantry items", "pantry":
            return .orange
        case "herbs & spices", "spices":
            return .purple
        default:
            return .gray
        }
    }
}

struct ShoppingItemRow: View {
    let item: String
    let isChecked: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Checkbox
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isChecked ? .green : .secondary)
                
                // Item text
                Text(item)
                    .font(.body)
                    .foregroundColor(isChecked ? .secondary : .primary)
                    .strikethrough(isChecked)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isChecked ? Color.green.opacity(0.1) : Color.clear)
            )
            .animation(.spring(response: 0.3), value: isChecked)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        ShoppingListView()
    }
}