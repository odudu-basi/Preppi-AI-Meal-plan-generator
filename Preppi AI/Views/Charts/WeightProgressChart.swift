import SwiftUI
import Charts

struct WeightProgressChart: View {
    let timeframe: ProgressTabView.TimeFrame
    let userData: UserOnboardingData
    
    // Mock data - in real app, this would come from user's weight tracking
    private var weightData: [WeightDataPoint] {
        generateMockWeightData()
    }
    
    private var targetWeightData: [WeightDataPoint] {
        generateTargetWeightData()
    }
    
    var body: some View {
        Chart {
            // Target weight line
            ForEach(targetWeightData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(.green.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
            
            // Actual weight line
            ForEach(weightData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 3))
            }
            
            // Actual weight points
            ForEach(weightData) { point in
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(.blue)
                .symbolSize(50)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: getXAxisStride())) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYScale(domain: getYAxisDomain())
        .overlay(alignment: .topTrailing) {
            // Legend
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                    Text("Actual")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(.green.opacity(0.6))
                        .frame(width: 12, height: 2)
                    Text("Target")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 2)
            )
            .padding(.trailing, 8)
            .padding(.top, 8)
        }
    }
    
    private func generateMockWeightData() -> [WeightDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -timeframe.days, to: endDate) ?? endDate
        
        var data: [WeightDataPoint] = []
        let currentWeight = userData.weight
        let primaryGoal = userData.healthGoals.first ?? .maintainWeight
        
        // Generate realistic weight progression
        for i in 0..<timeframe.days {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                let progress = Double(i) / Double(timeframe.days)
                var weight = currentWeight
                
                switch primaryGoal {
                case .loseWeight:
                    // Gradual weight loss with some fluctuation
                    let expectedLoss = progress * 3.0 // 3 lbs over timeframe
                    let fluctuation = Double.random(in: -0.5...0.5)
                    weight = currentWeight - expectedLoss + fluctuation
                case .gainWeight:
                    // Gradual weight gain with some fluctuation
                    let expectedGain = progress * 2.0 // 2 lbs over timeframe
                    let fluctuation = Double.random(in: -0.3...0.3)
                    weight = currentWeight + expectedGain + fluctuation
                default:
                    // Maintenance with normal fluctuation
                    let fluctuation = Double.random(in: -1.0...1.0)
                    weight = currentWeight + fluctuation
                }
                
                data.append(WeightDataPoint(date: date, weight: weight))
            }
        }
        
        return data
    }
    
    private func generateTargetWeightData() -> [WeightDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -timeframe.days, to: endDate) ?? endDate
        
        var data: [WeightDataPoint] = []
        let currentWeight = userData.weight
        let targetWeight = userData.targetWeight ?? currentWeight
        let primaryGoal = userData.healthGoals.first ?? .maintainWeight
        
        for i in 0..<timeframe.days {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                let progress = Double(i) / Double(timeframe.days)
                var weight = currentWeight
                
                switch primaryGoal {
                case .loseWeight, .gainWeight:
                    // Linear progression towards target
                    let totalChange = targetWeight - currentWeight
                    let expectedChange = progress * totalChange * 0.3 // 30% of total change over timeframe
                    weight = currentWeight + expectedChange
                default:
                    // Maintenance - stay at current weight
                    weight = currentWeight
                }
                
                data.append(WeightDataPoint(date: date, weight: weight))
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
    
    private func getYAxisDomain() -> ClosedRange<Double> {
        let allWeights = weightData.map { $0.weight } + targetWeightData.map { $0.weight }
        let minWeight = allWeights.min() ?? userData.weight
        let maxWeight = allWeights.max() ?? userData.weight
        let padding = (maxWeight - minWeight) * 0.1 + 2.0 // Add padding
        
        return (minWeight - padding)...(maxWeight + padding)
    }
}

struct WeightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}
