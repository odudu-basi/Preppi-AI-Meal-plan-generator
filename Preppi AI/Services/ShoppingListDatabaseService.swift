import Foundation
import Supabase

// MARK: - Database Models
struct DatabaseShoppingListItem: Codable {
    let id: UUID?
    let userId: UUID
    let mealPlanId: UUID?
    let itemName: String
    let category: String
    let isChecked: Bool
    let checkedAt: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mealPlanId = "meal_plan_id"
        case itemName = "item_name"
        case category
        case isChecked = "is_checked"
        case checkedAt = "checked_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Shopping List Database Service
class ShoppingListDatabaseService: ObservableObject {
    private let supabase: SupabaseClient
    
    init() {
        self.supabase = SupabaseService.shared.client
    }
    
    // MARK: - CRUD Operations
    
    /// Save shopping list items for a meal plan
    func saveShoppingListItems(
        mealPlanId: UUID,
        shoppingList: [String: [String]]
    ) async throws {
        guard let userId = try await getCurrentUserId() else {
            throw DatabaseError.userNotAuthenticated
        }
        
        // First, delete existing shopping list items for this meal plan
        try await deleteShoppingListItems(mealPlanId: mealPlanId)
        
        // Create new shopping list items
        var itemsToInsert: [DatabaseShoppingListItem] = []
        
        for (category, items) in shoppingList {
            for item in items {
                let dbItem = DatabaseShoppingListItem(
                    id: nil,
                    userId: userId,
                    mealPlanId: mealPlanId,
                    itemName: item,
                    category: category,
                    isChecked: false,
                    checkedAt: nil,
                    createdAt: nil,
                    updatedAt: nil
                )
                itemsToInsert.append(dbItem)
            }
        }
        
        if !itemsToInsert.isEmpty {
            let _: [DatabaseShoppingListItem] = try await supabase
                .from("shopping_list_items")
                .insert(itemsToInsert)
                .select()
                .execute()
                .value
        }
        
        print("✅ Shopping list items saved for meal plan: \(mealPlanId)")
    }
    
    /// Load shopping list items for a meal plan
    func loadShoppingListItems(mealPlanId: UUID) async throws -> [DatabaseShoppingListItem] {
        guard let userId = try await getCurrentUserId() else {
            throw DatabaseError.userNotAuthenticated
        }
        
        let items: [DatabaseShoppingListItem] = try await supabase
            .from("shopping_list_items")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("meal_plan_id", value: mealPlanId.uuidString)
            .execute()
            .value
        
        print("✅ Loaded \(items.count) shopping list items for meal plan: \(mealPlanId)")
        return items
    }
    
    /// Update checked state of a shopping list item
    func updateItemCheckedState(
        mealPlanId: UUID,
        itemName: String,
        isChecked: Bool
    ) async throws {
        guard let userId = try await getCurrentUserId() else {
            throw DatabaseError.userNotAuthenticated
        }
        
        // First update the checked state
        let _: [DatabaseShoppingListItem] = try await supabase
            .from("shopping_list_items")
            .update(["is_checked": isChecked])
            .eq("user_id", value: userId.uuidString)
            .eq("meal_plan_id", value: mealPlanId.uuidString)
            .eq("item_name", value: itemName)
            .select()
            .execute()
            .value
        
        // Then update the timestamp
        if isChecked {
            let checkedAt = ISO8601DateFormatter().string(from: Date())
            let _: [DatabaseShoppingListItem] = try await supabase
                .from("shopping_list_items")
                .update(["checked_at": checkedAt])
                .eq("user_id", value: userId.uuidString)
                .eq("meal_plan_id", value: mealPlanId.uuidString)
                .eq("item_name", value: itemName)
                .select()
                .execute()
                .value
        } else {
            let _: [DatabaseShoppingListItem] = try await supabase
                .from("shopping_list_items")
                .update(["checked_at": AnyJSON.null])
                .eq("user_id", value: userId.uuidString)
                .eq("meal_plan_id", value: mealPlanId.uuidString)
                .eq("item_name", value: itemName)
                .select()
                .execute()
                .value
        }
        
        print("✅ Updated item '\(itemName)' checked state to: \(isChecked)")
    }
    
    /// Clear all checked items for a meal plan
    func clearAllCheckedItems(mealPlanId: UUID) async throws {
        guard let userId = try await getCurrentUserId() else {
            throw DatabaseError.userNotAuthenticated
        }
        
        // First update the checked state
        let _: [DatabaseShoppingListItem] = try await supabase
            .from("shopping_list_items")
            .update(["is_checked": false])
            .eq("user_id", value: userId.uuidString)
            .eq("meal_plan_id", value: mealPlanId.uuidString)
            .select()
            .execute()
            .value
        
        // Then clear the timestamps
        let _: [DatabaseShoppingListItem] = try await supabase
            .from("shopping_list_items")
            .update(["checked_at": AnyJSON.null])
            .eq("user_id", value: userId.uuidString)
            .eq("meal_plan_id", value: mealPlanId.uuidString)
            .select()
            .execute()
            .value
        
        print("✅ Cleared all checked items for meal plan: \(mealPlanId)")
    }
    
    /// Delete all shopping list items for a meal plan
    private func deleteShoppingListItems(mealPlanId: UUID) async throws {
        guard let userId = try await getCurrentUserId() else {
            throw DatabaseError.userNotAuthenticated
        }
        
        try await supabase
            .from("shopping_list_items")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("meal_plan_id", value: mealPlanId.uuidString)
            .execute()
        
        print("✅ Deleted existing shopping list items for meal plan: \(mealPlanId)")
    }
    
    // MARK: - Helper Functions
    
    private func getCurrentUserId() async throws -> UUID? {
        do {
            let session = try await supabase.auth.session
            return UUID(uuidString: session.user.id.uuidString)
        } catch {
            print("❌ Error getting current user: \(error)")
            return nil
        }
    }
}

// MARK: - Database Error
enum DatabaseError: Error, LocalizedError {
    case userNotAuthenticated
    case invalidData
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .invalidData:
            return "Invalid data format"
        case .networkError:
            return "Network connection error"
        }
    }
}