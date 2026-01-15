import Foundation

// MARK: - Meal Plan Flow Models

struct MealPlanFlowData: Codable {
    var selectedDays: [Date]
    var availableProteins: [String]
    var availableCarbs: [String]
    var availableFats: [String]
    var availableSpices: [String]
    var specificMealRequests: String

    init() {
        self.selectedDays = []
        self.availableProteins = []
        self.availableCarbs = []
        self.availableFats = []
        self.availableSpices = []
        self.specificMealRequests = ""
    }
}

// MARK: - Available Food Options

enum AvailableFoodOptions {
    static let proteins = [
        "Chicken", "Beef", "Fish", "Tuna", "Shrimp", "Egg",
        "Turkey", "Pork", "Ham", "Tofu", "Soy Meat", "Tempeh",
        "Seitan", "Protein Powder"
    ]

    static let carbs = [
        "Rice", "Potato", "Sweet Potato", "Pasta", "Bread",
        "Quinoa", "Oats", "Couscous", "Barley", "Beans",
        "Lentils", "Chickpeas", "Corn"
    ]

    static let fats = [
        "Olive Oil", "Butter", "Coconut Oil", "Avocado",
        "Nuts", "Seeds", "Cheese", "Cream", "Peanut Butter",
        "Almond Butter"
    ]

    static let spices = [
        "Salt", "Pepper", "Garlic", "Onion", "Paprika",
        "Cumin", "Turmeric", "Ginger", "Chili", "Oregano",
        "Basil", "Thyme", "Rosemary", "Cinnamon", "Curry Powder"
    ]
}
