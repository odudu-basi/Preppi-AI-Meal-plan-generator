import SwiftUI

struct CompletedMealCard: View {
    let mealInstance: MealInstance
    let selectedDate: Date
    let selectedBreakfastMeal: DayMeal?
    let selectedLunchMeal: DayMeal?
    let selectedDinnerMeal: DayMeal?
    
    // Get the actual meal details based on meal type
    private var dayMeal: DayMeal? {
        switch mealInstance.mealType.lowercased() {
        case "breakfast":
            return selectedBreakfastMeal
        case "lunch":
            return selectedLunchMeal
        case "dinner":
            return selectedDinnerMeal
        default:
            return nil
        }
    }
    
    var body: some View {
        if let dayMeal = dayMeal {
            // Display the actual meal from the meal plan
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Meal image
                    Group {
                        if let imageUrl = dayMeal.meal.imageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .scaleEffect(0.5)
                            }
                        } else {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                    
                    // Meal info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dayMeal.meal.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        
                        Text(mealInstance.mealType.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Show completion status
                        HStack(spacing: 4) {
                            Image(systemName: mealInstance.completion.icon)
                                .font(.caption)
                                .foregroundColor(mealInstance.completion.color)
                            
                            Text(mealInstance.completion.displayName)
                                .font(.caption)
                                .foregroundColor(mealInstance.completion.color)
                        }
                    }
                    
                    Spacer()
                    
                    // Calories
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(dayMeal.meal.calories)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("cal/serving")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(mealInstance.completion.color.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        } else {
            // Fallback for meals without details
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Generic meal icon
                    Image(systemName: "fork.knife")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    
                    // Meal info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(mealInstance.mealType.capitalized) Completed")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // Show completion status
                        HStack(spacing: 4) {
                            Image(systemName: mealInstance.completion.icon)
                                .font(.caption)
                                .foregroundColor(mealInstance.completion.color)
                            
                            Text(mealInstance.completion.displayName)
                                .font(.caption)
                                .foregroundColor(mealInstance.completion.color)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(mealInstance.completion.color.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }
}

#Preview {
    CompletedMealCard(
        mealInstance: MealInstance(
            id: UUID(),
            date: Date(),
            mealType: "dinner",
            completion: .ateExact,
            completedAt: Date()
        ),
        selectedDate: Date(),
        selectedBreakfastMeal: nil,
        selectedLunchMeal: nil,
        selectedDinnerMeal: nil
    )
}
