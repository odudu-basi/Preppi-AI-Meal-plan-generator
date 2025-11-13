import SwiftUI

struct LoggedMealCard: View {
    let loggedMeal: LoggedMeal
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Meal image or placeholder
                Group {
                    if let image = loggedMeal.image {
                        // Local image (temporary)
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if let imageUrl = loggedMeal.imageUrl, let url = URL(string: imageUrl) {
                        // Remote image from database
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
                        // No image placeholder
                        Image(systemName: "camera.fill")
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
                    Text(loggedMeal.mealName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Text("Logged Meal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatTime(loggedMeal.loggedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Calories
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(loggedMeal.calories)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Navigation arrow
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    LoggedMealCard(
        loggedMeal: LoggedMeal(
            from: MealAnalysisResult(
                mealName: "Grilled Chicken Salad",
                description: "Fresh mixed greens with grilled chicken breast",
                macros: Macros(
                    protein: 35.0,
                    carbohydrates: 12.0,
                    fat: 8.0,
                    fiber: 4.0,
                    sugar: 6.0,
                    sodium: 450.0
                ),
                calories: 250,
                healthScore: 9
            ),
            image: nil
        ),
        onTap: {}
    )
    .padding()
}
