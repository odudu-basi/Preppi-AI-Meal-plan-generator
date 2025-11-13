import SwiftUI
import Charts

struct CalorieProgressChart: View {
    let timeframe: ProgressTabView.TimeFrame
    let userData: UserOnboardingData
    
    // Mock data - in real app, this would come from user's meal tracking
    private var calorieData: [CalorieDataPoint] {
        generateMockCalorieData()
    }
    
    private var dailyCalorieGoal: Int {
        CalorieCalculationService.shared.calculateDailyCalorieGoal(for: userData)
    }
    
    var body: some View {
        Chart {
            // Daily calorie goal line
            RuleMark(y: .value("Goal", dailyCalorieGoal))
                .foregroundStyle(.gray.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .annotation(position: .topTrailing, alignment: .trailing) {
                    Text("Goal: \(dailyCalorieGoal)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemBackground))
                        )
                }
            
            // Stacked bars for macros
            ForEach(calorieData) { point in
                // Protein (bottom)
                BarMark(
                    x: .value("Date", point.date),
                    yStart: .value("Start", 0),
                    yEnd: .value("Protein", point.proteinCalories)
                )
                .foregroundStyle(.red.opacity(0.8))
                .cornerRadius(2)
                
                // Carbs (middle)
                BarMark(
                    x: .value("Date", point.date),
                    yStart: .value("Start", point.proteinCalories),
                    yEnd: .value("Carbs", point.proteinCalories + point.carbCalories)
                )
                .foregroundStyle(.orange.opacity(0.8))
                .cornerRadius(2)
                
                // Fats (top)
                BarMark(
                    x: .value("Date", point.date),
                    yStart: .value("Start", point.proteinCalories + point.carbCalories),
                    yEnd: .value("Total", point.totalCalories)
                )
                .foregroundStyle(.blue.opacity(0.8))
                .cornerRadius(2)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: getXAxisStride())) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: getXAxisFormat())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYScale(domain: 0...getMaxCalories())
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                // Add subtle background pattern
                Rectangle()
                    .fill(Color(.systemGray6).opacity(0.1))
            }
        }
    }
    
    private func generateMockCalorieData() -> [CalorieDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -timeframe.days, to: endDate) ?? endDate
        
        var data: [CalorieDataPoint] = []
        let dailyGoal = dailyCalorieGoal
        
        for i in 0..<timeframe.days {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                // Generate realistic calorie intake with some variation
                let adherenceRate = Double.random(in: 0.7...1.1) // 70% to 110% of goal
                let totalCalories = Int(Double(dailyGoal) * adherenceRate)
                
                // Calculate macro breakdown (similar to nutrition plan ratios)
                let proteinCalories = Int(Double(totalCalories) * 0.30) // 30% protein
                let carbCalories = Int(Double(totalCalories) * 0.40)    // 40% carbs
                let fatCalories = totalCalories - proteinCalories - carbCalories // Remaining for fats
                
                data.append(CalorieDataPoint(
                    date: date,
                    totalCalories: totalCalories,
                    proteinCalories: proteinCalories,
                    carbCalories: carbCalories,
                    fatCalories: fatCalories
                ))
            }
        }
        
        return data
    }
    
    private func getXAxisStride() -> Calendar.Component {
        switch timeframe {
        case .week:
            return .day
        case .month:
            return .weekOfYear
        case .threeMonths:
            return .weekOfYear
        }
    }
    
    private func getXAxisFormat() -> Date.FormatStyle {
        switch timeframe {
        case .week:
            return .dateTime.weekday(.abbreviated)
        case .month:
            return .dateTime.day()
        case .threeMonths:
            return .dateTime.month(.abbreviated).day()
        }
    }
    
    private func getMaxCalories() -> Int {
        let maxFromData = calorieData.map { $0.totalCalories }.max() ?? dailyCalorieGoal
        return max(maxFromData, dailyCalorieGoal) + 200 // Add padding
    }
}

struct CalorieDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let totalCalories: Int
    let proteinCalories: Int
    let carbCalories: Int
    let fatCalories: Int
}
