import SwiftUI

// MARK: - Macros Display Component
struct MacrosView: View {
    let macros: Macros
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                
                Text("Nutrition Facts")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Primary Macros (Protein, Carbs, Fat)
                HStack(spacing: 12) {
                    MacroCircularProgress(
                        title: "Protein",
                        value: macros.protein,
                        unit: "g",
                        color: .red,
                        totalCalories: macros.totalCalories
                    )
                    
                    MacroCircularProgress(
                        title: "Carbs",
                        value: macros.carbohydrates,
                        unit: "g",
                        color: .blue,
                        totalCalories: macros.totalCalories
                    )
                    
                    MacroCircularProgress(
                        title: "Fat",
                        value: macros.fat,
                        unit: "g",
                        color: .orange,
                        totalCalories: macros.totalCalories
                    )
                }
                
                Divider()
                    .background(Color(.systemGray4))
                
                // Secondary Nutrients
                VStack(spacing: 8) {
                    MacroDetailRow(
                        icon: "leaf.fill",
                        title: "Fiber",
                        value: macros.fiber,
                        unit: "g",
                        color: .green
                    )
                    
                    MacroDetailRow(
                        icon: "drop.fill",
                        title: "Sugar",
                        value: macros.sugar,
                        unit: "g",
                        color: .purple
                    )
                    
                    MacroDetailRow(
                        icon: "saltshaker.fill",
                        title: "Sodium",
                        value: macros.sodium,
                        unit: "mg",
                        color: .gray
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
        )
    }
}

// MARK: - Circular Progress for Main Macros
struct MacroCircularProgress: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    let totalCalories: Int
    
    private var percentage: Double {
        let caloriesFromMacro: Double
        switch title {
        case "Protein":
            caloriesFromMacro = value * 4
        case "Carbs":
            caloriesFromMacro = value * 4
        case "Fat":
            caloriesFromMacro = value * 9
        default:
            caloriesFromMacro = 0
        }
        return totalCalories > 0 ? min(caloriesFromMacro / Double(totalCalories), 1.0) : 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: percentage)
                
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", value))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Detail Row for Secondary Nutrients
struct MacroDetailRow: View {
    let icon: String
    let title: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(String(format: "%.1f", value)) \(unit)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.05))
        )
    }
}

// MARK: - Enhanced Compact Macros Summary
struct CompactMacrosView: View {
    let macros: Macros
    
    var body: some View {
        VStack(spacing: 12) {
            // Nutrition header without calories display
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Nutritional Breakdown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Enhanced macro breakdown with progress bars
            VStack(spacing: 8) {
                EnhancedMacroRow(
                    icon: "person.fill",
                    title: "Protein",
                    value: macros.protein,
                    unit: "g",
                    color: .red,
                    percentage: proteinPercentage
                )
                
                EnhancedMacroRow(
                    icon: "leaf.fill",
                    title: "Carbs", 
                    value: macros.carbohydrates,
                    unit: "g",
                    color: .blue,
                    percentage: carbPercentage
                )
                
                EnhancedMacroRow(
                    icon: "drop.fill",
                    title: "Fat",
                    value: macros.fat,
                    unit: "g", 
                    color: .orange,
                    percentage: fatPercentage
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color("AppBackground"),
                            Color(.systemGray6).opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // Calculate macro percentages for visual representation
    private var proteinPercentage: Double {
        let proteinCalories = macros.protein * 4
        return macros.totalCalories > 0 ? min(proteinCalories / Double(macros.totalCalories), 1.0) : 0
    }
    
    private var carbPercentage: Double {
        let carbCalories = macros.carbohydrates * 4
        return macros.totalCalories > 0 ? min(carbCalories / Double(macros.totalCalories), 1.0) : 0
    }
    
    private var fatPercentage: Double {
        let fatCalories = macros.fat * 9
        return macros.totalCalories > 0 ? min(fatCalories / Double(macros.totalCalories), 1.0) : 0
    }
}

// MARK: - Enhanced Macro Row with Progress Bar
struct EnhancedMacroRow: View {
    let icon: String
    let title: String
    let value: Double
    let unit: String
    let color: Color
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with background
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            // Title and value
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Text("\(String(format: "%.1f", value))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(unit)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.15))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.8), color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * percentage, height: 6)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentage)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.15), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Individual Macro Chip
struct MacroChip: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            
            Text(String(format: "%.0f", value))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(unit)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        MacrosView(macros: Macros(
            protein: 45.5,
            carbohydrates: 55.2,
            fat: 18.7,
            fiber: 8.3,
            sugar: 12.1,
            sodium: 890.5
        ))
        
        CompactMacrosView(macros: Macros(
            protein: 45.5,
            carbohydrates: 55.2,
            fat: 18.7,
            fiber: 8.3,
            sugar: 12.1,
            sodium: 890.5
        ))
        
        // Preview of the enhanced macro row
        EnhancedMacroRow(
            icon: "person.fill",
            title: "Protein",
            value: 45.5,
            unit: "g",
            color: .red,
            percentage: 0.35
        )
    }
    .padding()
}