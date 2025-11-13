//
//  TargetWeightView.swift
//  Preppi AI
//
//  Created for target weight input
//

import SwiftUI

struct TargetWeightView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var selectedTargetWeight: Int = 150
    @State private var selectedMinWeight: Int = 150
    @State private var selectedMaxWeight: Int = 160
    @State private var animateContent = false

    // Base weight range
    private let baseWeightRange = 80...400
    
    // Computed properties for smart weight selection
    private var currentWeight: Int {
        Int(coordinator.userData.weight)
    }
    
    private var hasWeightLossGoal: Bool {
        coordinator.userData.healthGoals.contains(.loseWeight)
    }
    
    private var hasWeightGainGoal: Bool {
        coordinator.userData.healthGoals.contains(.gainWeight)
    }
    
    private var hasWeightMaintenanceGoal: Bool {
        coordinator.userData.healthGoals.contains(.maintainWeight)
    }
    
    private var filteredWeightRange: ClosedRange<Int> {
        if hasWeightLossGoal {
            // For weight loss: only show weights below current weight
            return baseWeightRange.lowerBound...min(currentWeight - 1, baseWeightRange.upperBound)
        } else if hasWeightGainGoal {
            // For weight gain: only show weights above current weight
            return max(currentWeight + 1, baseWeightRange.lowerBound)...baseWeightRange.upperBound
        } else {
            // For maintenance or other goals: show full range
            return baseWeightRange
        }
    }
    
    private var headerTitle: String {
        if hasWeightMaintenanceGoal {
            return "Weight Range"
        } else {
            return "Target Weight"
        }
    }
    
    private var headerSubtitle: String {
        if hasWeightMaintenanceGoal {
            return "What's your ideal weight range?"
        } else if hasWeightLossGoal {
            return "What's your goal weight?"
        } else if hasWeightGainGoal {
            return "What's your target weight?"
        } else {
            return "What's your goal weight?"
        }
    }

    var body: some View {
        OnboardingContainer {
            VStack(spacing: 20) {
                // Navigation bar with progress
                OnboardingNavigationBar(
                    currentStep: coordinator.currentStep.stepNumber,
                    totalSteps: OnboardingStep.totalSteps,
                    canGoBack: true,
                    onBackTapped: {
                        coordinator.previousStep()
                    }
                )

                // Scrollable content
                ScrollView {
                    VStack(spacing: 35) {
                        // Header Section
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(animateContent ? 1.0 : 0.8)
                                    .opacity(animateContent ? 1.0 : 0.0)

                                Image(systemName: "target")
                                    .font(.system(size: 50, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .scaleEffect(animateContent ? 1.0 : 0.8)
                                    .opacity(animateContent ? 1.0 : 0.0)
                            }

                            VStack(spacing: 8) {
                                Text(headerTitle)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .opacity(animateContent ? 1.0 : 0.0)
                                    .offset(y: animateContent ? 0 : 20)

                                Text(headerSubtitle)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .opacity(animateContent ? 1.0 : 0.0)
                                    .offset(y: animateContent ? 0 : 20)
                            }
                        }
                        .padding(.top, 30)

                        // Weight Picker Card
                        VStack(spacing: 20) {
                            Text(hasWeightMaintenanceGoal ? "Weight Range" : "Target Weight")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            if hasWeightMaintenanceGoal {
                                // Weight Range Selection for Maintenance
                                VStack(spacing: 16) {
                                    // Display selected range
                                    HStack(spacing: 8) {
                                        Text("\(selectedMinWeight)")
                                            .font(.system(size: 40, weight: .bold, design: .rounded))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.green, .mint],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                        
                                        Text("-")
                                            .font(.system(size: 30, weight: .medium))
                                            .foregroundColor(.secondary)
                                        
                                        Text("\(selectedMaxWeight)")
                                            .font(.system(size: 40, weight: .bold, design: .rounded))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.green, .mint],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                    
                                    Text("pounds")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    // Range Pickers
                                    HStack(spacing: 20) {
                                        VStack(spacing: 8) {
                                            Text("Minimum")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.secondary)
                                            
                                            Picker("Min Weight", selection: $selectedMinWeight) {
                                                ForEach(filteredWeightRange, id: \.self) { weight in
                                                    Text("\(weight)")
                                                        .tag(weight)
                                                }
                                            }
                                            .pickerStyle(.wheel)
                                            .frame(height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                        
                                        VStack(spacing: 8) {
                                            Text("Maximum")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.secondary)
                                            
                                            Picker("Max Weight", selection: $selectedMaxWeight) {
                                                ForEach(filteredWeightRange, id: \.self) { weight in
                                                    Text("\(weight)")
                                                        .tag(weight)
                                                }
                                            }
                                            .pickerStyle(.wheel)
                                            .frame(height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                    }
                                }
                            } else {
                                // Single Weight Selection for Loss/Gain
                                VStack(spacing: 16) {
                                    // Large display of selected weight
                                    VStack(spacing: 8) {
                                        Text("\(selectedTargetWeight)")
                                            .font(.system(size: 60, weight: .bold, design: .rounded))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.green, .mint],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )

                                        Text("pounds")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }

                                    // Scrollable Picker with filtered range
                                    Picker("Target Weight", selection: $selectedTargetWeight) {
                                        ForEach(filteredWeightRange, id: \.self) { weight in
                                            Text("\(weight)")
                                                .tag(weight)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                }
                            }

                            // Helpful info
                            if coordinator.userData.weight > 0 {
                                let currentWeight = coordinator.userData.weight
                                
                                if hasWeightMaintenanceGoal {
                                    // Show maintenance range info
                                    let rangeSize = selectedMaxWeight - selectedMinWeight
                                    HStack(spacing: 8) {
                                        Image(systemName: "target")
                                            .foregroundColor(.orange)
                                        Text("Maintain within \(rangeSize) lb range")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.orange.opacity(0.1))
                                    )
                                } else {
                                    // Show loss/gain info
                                    let weightDifference = currentWeight - Double(selectedTargetWeight)
                                    if weightDifference > 0 {
                                        HStack(spacing: 8) {
                                            Image(systemName: "arrow.down.circle.fill")
                                                .foregroundColor(.green)
                                            Text("Goal: Lose \(Int(weightDifference)) lbs")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.green.opacity(0.1))
                                        )
                                    } else if weightDifference < 0 {
                                        HStack(spacing: 8) {
                                            Image(systemName: "arrow.up.circle.fill")
                                                .foregroundColor(.blue)
                                            Text("Goal: Gain \(Int(abs(weightDifference))) lbs")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.blue.opacity(0.1))
                                        )
                                    }
                                }
                            }
                        }
                        .padding(25)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 30)

                        Spacer(minLength: 20)
                    }
                }

                // Continue button
                VStack(spacing: 25) {
                    PremiumContinueButton(
                        isEnabled: hasWeightMaintenanceGoal ? selectedMinWeight < selectedMaxWeight : true,
                        animateContent: animateContent
                    ) {
                        if hasWeightMaintenanceGoal {
                            coordinator.userData.targetWeightRange = WeightRange(min: Double(selectedMinWeight), max: Double(selectedMaxWeight))
                            coordinator.userData.targetWeight = nil
                        } else {
                            coordinator.userData.targetWeight = Double(selectedTargetWeight)
                            coordinator.userData.targetWeightRange = nil
                        }
                        coordinator.nextStep()
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 10)
            }
        }
        .onAppear {
            setupInitialValues()
            
            // Animate content
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
        .onChange(of: selectedMinWeight) { newValue in
            // Ensure max weight is always greater than min weight
            if newValue >= selectedMaxWeight {
                selectedMaxWeight = min(newValue + 5, filteredWeightRange.upperBound)
            }
        }
        .onChange(of: selectedMaxWeight) { newValue in
            // Ensure min weight is always less than max weight
            if newValue <= selectedMinWeight {
                selectedMinWeight = max(newValue - 5, filteredWeightRange.lowerBound)
            }
        }
    }
    
    private func setupInitialValues() {
        let currentWeight = Int(coordinator.userData.weight)
        
        if hasWeightMaintenanceGoal {
            // Set up weight range for maintenance
            if let existingRange = coordinator.userData.targetWeightRange {
                selectedMinWeight = Int(existingRange.min)
                selectedMaxWeight = Int(existingRange.max)
            } else {
                // Default to ±5 lbs around current weight
                selectedMinWeight = max(currentWeight - 5, filteredWeightRange.lowerBound)
                selectedMaxWeight = min(currentWeight + 5, filteredWeightRange.upperBound)
            }
        } else {
            // Set up single target weight for loss/gain
            if let targetWeight = coordinator.userData.targetWeight, targetWeight > 0 {
                selectedTargetWeight = Int(targetWeight)
            } else if currentWeight > 0 {
                if hasWeightLossGoal {
                    // Default to 10% less than current weight
                    selectedTargetWeight = max(Int(Double(currentWeight) * 0.9), filteredWeightRange.lowerBound)
                } else if hasWeightGainGoal {
                    // Default to 10% more than current weight
                    selectedTargetWeight = min(Int(Double(currentWeight) * 1.1), filteredWeightRange.upperBound)
                } else {
                    // Default to current weight for other goals
                    selectedTargetWeight = currentWeight
                }
            }
            
            // Ensure selected weight is within the filtered range
            selectedTargetWeight = max(filteredWeightRange.lowerBound, min(selectedTargetWeight, filteredWeightRange.upperBound))
        }
    }
}

#Preview {
    TargetWeightView(coordinator: OnboardingCoordinator())
}
