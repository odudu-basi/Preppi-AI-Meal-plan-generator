import SwiftUI

struct ShoppingListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var databaseService = ShoppingListDatabaseService()
    
    let mealPlanId: UUID
    let weekIdentifier: String? // Week identifier for this shopping list
    
    @State private var shoppingList: [String: [String]] = [:]
    @State private var checkedItems: Set<String> = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
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
            
            if isLoading {
                loadingView
            } else if shoppingList.isEmpty {
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
                                    checkedItems: $checkedItems,
                                    mealPlanId: mealPlanId,
                                    databaseService: databaseService
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
                    Task {
                        await clearAllItems()
                    }
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.green)
                .disabled(checkedItems.isEmpty)
            }
        }
        .onAppear {
            Task {
                await loadShoppingListAndCheckedStates()
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
            
            Text("Loading shopping list...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("AppBackground").ignoresSafeArea())
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
                    .background(Color("AppBackground").ignoresSafeArea())
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
            
            VStack(spacing: 8) {
                Text("Everything you need for your weekly meal plan")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Week of \(formatWeekIdentifier(getCurrentWeekIdentifier()))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.1))
                    )
            }
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
    
    /// Generate a week identifier from a given date (format: yyyy-MM-dd for week start)
    private func getWeekIdentifier(for date: Date) -> String {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday is first day
        
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: weekStart)
    }
    
    /// Get the current week identifier or use the provided one
    private func getCurrentWeekIdentifier() -> String {
        return weekIdentifier ?? getWeekIdentifier(for: Date())
    }
    
    /// Format week identifier for display (convert yyyy-MM-dd to readable format)
    private func formatWeekIdentifier(_ weekId: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: weekId) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy"
            return displayFormatter.string(from: date)
        }
        
        return weekId // Fallback to original format
    }
    
    /// Load shopping list structure and checked states from database
    private func loadShoppingListAndCheckedStates() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // First load the shopping list structure from UserDefaults (generated shopping list)
            await loadShoppingListStructure()
            
            // If we have a shopping list, try to load or create database entries
            if !shoppingList.isEmpty {
                // Check if database items exist for this meal plan
                let existingItems = try await databaseService.loadShoppingListItems(mealPlanId: mealPlanId)
                
                if existingItems.isEmpty {
                    // No database items exist, create them from the shopping list structure
                    await createDatabaseItemsFromShoppingList()
                } else {
                    // Load checked states from existing database items
                    await loadCheckedStatesFromDatabase(existingItems)
                }
            }
        } catch {
            errorMessage = "Failed to load shopping list: \(error.localizedDescription)"
            print("❌ Error loading shopping list: \(error)")
        }
        
        isLoading = false
    }
    
    /// Load shopping list structure from UserDefaults (aggregating all meal types)
    private func loadShoppingListStructure() async {
        var aggregatedShoppingList: [String: [String]] = [:]
        
        // Load shopping lists for all meal types for the specific week
        let mealTypes = ["breakfast", "lunch", "dinner"]
        let weekKey = getCurrentWeekIdentifier()
        
        // Get current user ID for user-specific shopping list loading
        let userId = try? await getCurrentUserId()
        let userKey = userId?.uuidString ?? "unknown"
        
        print("🛒 DEBUG: Loading shopping lists for user \(userKey) in week: \(weekKey)")
        
        for mealType in mealTypes {
            // Load user-specific, week-specific shopping lists
            let userSpecificKey = "user_\(userKey)_weeklyShoppingList_\(mealType)_\(weekKey)"
            
            if let shoppingListString = UserDefaults.standard.string(forKey: userSpecificKey),
               let data = shoppingListString.data(using: .utf8),
               let decodedList = try? JSONSerialization.jsonObject(with: data) as? [String: [String]] {
                
                print("🛒 DEBUG: Found shopping list for \(mealType) in week \(weekKey): \(decodedList.keys.count) categories")
                
                // Merge this meal type's shopping list into the aggregated list
                for (category, items) in decodedList {
                    if aggregatedShoppingList[category] != nil {
                        // Category exists, merge items and remove duplicates
                        let existingItems = Set(aggregatedShoppingList[category]!)
                        let newItems = Set(items)
                        let mergedItems = Array(existingItems.union(newItems)).sorted()
                        aggregatedShoppingList[category] = mergedItems
                        print("🛒 DEBUG: Merged \(items.count) items into existing category '\(category)'")
                    } else {
                        // New category, add all items
                        aggregatedShoppingList[category] = items.sorted()
                        print("🛒 DEBUG: Added new category '\(category)' with \(items.count) items")
                    }
                }
            } else {
                print("🛒 DEBUG: No shopping list found for \(mealType) in week \(weekKey)")
            }
        }
        
        print("🛒 DEBUG: Final aggregated shopping list has \(aggregatedShoppingList.keys.count) categories")
        
        // Clean up old shopping lists from different weeks to prevent confusion
        await cleanupOldShoppingLists(currentWeekKey: weekKey, userKey: userKey)
        
        // Also clean up any old-format shopping lists that might exist from previous users
        await cleanupOldFormatShoppingLists()
        
        await MainActor.run {
            shoppingList = aggregatedShoppingList
        }
    }
    
    /// Create database items from shopping list structure
    private func createDatabaseItemsFromShoppingList() async {
        do {
            try await databaseService.saveShoppingListItems(
                mealPlanId: mealPlanId,
                shoppingList: shoppingList
            )
            print("✅ Created database items for shopping list")
        } catch {
            print("❌ Error creating database items: \(error)")
        }
    }
    
    /// Load checked states from database items
    private func loadCheckedStatesFromDatabase(_ items: [DatabaseShoppingListItem]) async {
        await MainActor.run {
            checkedItems = Set(items.filter { $0.isChecked }.map { $0.itemName })
            print("✅ Loaded \(checkedItems.count) checked items from database")
        }
    }
    
    /// Clear all checked items
    private func clearAllItems() async {
        do {
            try await databaseService.clearAllCheckedItems(mealPlanId: mealPlanId)
            await MainActor.run {
                checkedItems.removeAll()
            }
            print("✅ Cleared all checked items")
        } catch {
            print("❌ Error clearing items: \(error)")
            await MainActor.run {
                errorMessage = "Failed to clear items: \(error.localizedDescription)"
            }
        }
    }
    
    /// Clean up old shopping lists from UserDefaults to prevent week confusion
    private func cleanupOldShoppingLists(currentWeekKey: String, userKey: String) async {
        let mealTypes = ["breakfast", "lunch", "dinner"]
        
        // Get all UserDefaults keys
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        
        for key in allKeys {
            // Check if this is a shopping list key for this specific user
            if key.hasPrefix("user_\(userKey)_weeklyShoppingList_") {
                // Check if it's an old format key (without week identifier)
                let isOldFormat = mealTypes.contains { mealType in
                    key == "user_\(userKey)_weeklyShoppingList_\(mealType)"
                }
                
                // Check if it's for a different week
                let isDifferentWeek = mealTypes.contains { mealType in
                    key.hasPrefix("user_\(userKey)_weeklyShoppingList_\(mealType)_") && 
                    key != "user_\(userKey)_weeklyShoppingList_\(mealType)_\(currentWeekKey)"
                }
                
                if isOldFormat || isDifferentWeek {
                    UserDefaults.standard.removeObject(forKey: key)
                    print("🛒 DEBUG: Cleaned up old shopping list key for user \(userKey): \(key)")
                }
            }
        }
        
        print("🛒 DEBUG: Shopping list cleanup completed for user \(userKey) in week \(currentWeekKey)")
    }
    
    /// Get the current authenticated user's ID
    private func getCurrentUserId() async throws -> UUID? {
        do {
            let session = try await SupabaseService.shared.auth.session
            return UUID(uuidString: session.user.id.uuidString)
        } catch {
            print("❌ Error getting current user: \(error)")
            return nil
        }
    }
    
    /// Clean up any old-format shopping lists that might exist from previous users
    private func cleanupOldFormatShoppingLists() async {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        
        // Find and remove old-format shopping list keys (without user prefix)
        let oldFormatKeys = allKeys.filter { key in
            key.hasPrefix("weeklyShoppingList_") && !key.contains("user_")
        }
        
        for key in oldFormatKeys {
            UserDefaults.standard.removeObject(forKey: key)
            print("🗑️ Cleaned up old-format shopping list key: \(key)")
        }
        
        if !oldFormatKeys.isEmpty {
            print("🛒 DEBUG: Cleaned up \(oldFormatKeys.count) old-format shopping list keys")
        }
    }
}

// MARK: - Supporting Views

struct ShoppingCategorySection: View {
    let category: String
    let items: [String]
    @Binding var checkedItems: Set<String>
    let mealPlanId: UUID
    let databaseService: ShoppingListDatabaseService
    
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
                            Task {
                                await toggleItemCheckedState(item)
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
    
    /// Toggle item checked state and save to database
    private func toggleItemCheckedState(_ item: String) async {
        let newCheckedState = !checkedItems.contains(item)
        
        do {
            // Update database first
            try await databaseService.updateItemCheckedState(
                mealPlanId: mealPlanId,
                itemName: item,
                isChecked: newCheckedState
            )
            
            // Update local state on success
            await MainActor.run {
                if newCheckedState {
                    checkedItems.insert(item)
                } else {
                    checkedItems.remove(item)
                }
            }
            
            print("✅ Toggled item '\(item)' to: \(newCheckedState)")
        } catch {
            print("❌ Error toggling item '\(item)': \(error)")
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
        ShoppingListView(mealPlanId: UUID(), weekIdentifier: nil)
    }
}

