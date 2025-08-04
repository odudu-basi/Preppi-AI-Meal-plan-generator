//
//  PhysicalStatsView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI

struct PhysicalStatsView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var selectedAge: Int = 25
    @State private var selectedWeight: Int = 150
    @State private var selectedHeight: Int = 68
    @State private var selectedActivityLevel: ActivityLevel = .sedentary
    
    // Picker ranges
    private let ageRange = 16...100
    private let weightRange = 80...400
    private let heightRange = 48...84
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.15),
                    Color(.systemBackground),
                    Color.green.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator - Fixed at top
                OnboardingNavigationBar(
                    currentStep: 7,
                    totalSteps: OnboardingStep.totalSteps,
                    canGoBack: true,
                    onBackTapped: {
                        coordinator.previousStep()
                    }
                )
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 35) {
                        // Premium Header Section
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
                                
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 50, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            VStack(spacing: 8) {
                                Text("Physical Profile")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Help us personalize your health journey")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 30)
                        
                        // Premium Stats Card
                        VStack(spacing: 25) {
                            // Basic Stats Section
                            VStack(spacing: 20) {
                                SectionHeader(title: "Basic Information", icon: "person.fill")
                                
                                HStack(spacing: 16) {
                                    PremiumScrollablePicker(
                                        title: "Age",
                                        selectedValue: $selectedAge,
                                        range: ageRange,
                                        suffix: "years",
                                        icon: "calendar"
                                    )
                                    
                                    PremiumScrollablePicker(
                                        title: "Weight",
                                        selectedValue: $selectedWeight,
                                        range: weightRange,
                                        suffix: "lbs",
                                        icon: "scalemass"
                                    )
                                }
                                
                                PremiumScrollablePicker(
                                    title: "Height",
                                    selectedValue: $selectedHeight,
                                    range: heightRange,
                                    suffix: "inches",
                                    icon: "ruler"
                                )
                            }
                            
                            // Activity Level Section
                            VStack(spacing: 20) {
                                SectionHeader(title: "Activity Level", icon: "bolt.fill")
                                
                                VStack(spacing: 12) {
                                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                                        PremiumActivityCard(
                                            level: level,
                                            isSelected: selectedActivityLevel == level
                                        ) {
                                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                                selectedActivityLevel = level
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Add bottom padding for scroll
                        Color.clear.frame(height: 120)
                    }
                }
                
                // Premium Navigation Buttons
                VStack {
                    PhysicalStatsNavigationButtons(
                        onBack: { coordinator.previousStep() },
                        onNext: { 
                            withAnimation(.easeInOut(duration: 0.3)) {
                                saveAndContinue()
                            }
                        },
                        isNextEnabled: isFormValid
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .onAppear {
            // Load existing values if available
            if coordinator.userData.age > 0 {
                selectedAge = coordinator.userData.age
            }
            if coordinator.userData.weight > 0 {
                selectedWeight = Int(coordinator.userData.weight)
            }
            if coordinator.userData.height > 0 {
                selectedHeight = coordinator.userData.height
            }
            selectedActivityLevel = coordinator.userData.activityLevel
        }
    }
    
    private var isFormValid: Bool {
        // Always valid since we have default selections
        true
    }
    
    private func saveAndContinue() {
        coordinator.userData.age = selectedAge
        coordinator.userData.weight = Double(selectedWeight)
        coordinator.userData.height = selectedHeight
        coordinator.userData.activityLevel = selectedActivityLevel
        coordinator.nextStep()
    }
}

// MARK: - Premium Components

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.green)
            
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct PremiumScrollablePicker: View {
    let title: String
    @Binding var selectedValue: Int
    let range: ClosedRange<Int>
    let suffix: String
    let icon: String
    @State private var showingPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green)
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showingPicker = true
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green.opacity(0.7))
                        .frame(width: 20)
                    
                    Text("\(selectedValue)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(suffix)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingPicker) {
            PremiumPickerModal(
                title: title,
                selectedValue: $selectedValue,
                range: range,
                suffix: suffix,
                icon: icon,
                isPresented: $showingPicker
            )
        }
    }
}

struct PremiumPickerModal: View {
    let title: String
    @Binding var selectedValue: Int
    let range: ClosedRange<Int>
    let suffix: String
    let icon: String
    @Binding var isPresented: Bool
    @State private var tempSelection: Int
    
    init(title: String, selectedValue: Binding<Int>, range: ClosedRange<Int>, suffix: String, icon: String, isPresented: Binding<Bool>) {
        self.title = title
        self._selectedValue = selectedValue
        self.range = range
        self.suffix = suffix
        self.icon = icon
        self._isPresented = isPresented
        self._tempSelection = State(initialValue: selectedValue.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.1), .blue.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Select \(title)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Choose your \(title.lowercased())")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 30)
                .padding(.horizontal, 20)
                
                // Custom Picker
                VStack {
                    Text("\(tempSelection) \(suffix)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.vertical, 20)
                    
                    Picker("", selection: $tempSelection) {
                        ForEach(Array(range), id: \.self) { value in
                            Text("\(value)")
                                .font(.system(size: 18, weight: .medium))
                                .tag(value)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 200)
                    .clipped()
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        selectedValue = tempSelection
                        withAnimation(.spring(response: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("Confirm")
                                .font(.system(size: 16, weight: .semibold))
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct PremiumActivityCard: View {
    let level: ActivityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Activity icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white : Color.green.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: activityIcon(for: level))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .green : .green.opacity(0.7))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(level.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white : Color.clear)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color(.systemBackground), Color(.systemBackground)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(
                        color: isSelected ? Color.green.opacity(0.2) : Color.black.opacity(0.05),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.clear : Color.gray.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func activityIcon(for level: ActivityLevel) -> String {
        switch level {
        case .sedentary: return "figure.seated.side"
        case .lightlyActive: return "figure.walk"
        case .moderatelyActive: return "figure.run"
        case .veryActive: return "figure.strengthtraining.traditional"
        case .extremelyActive: return "flame.fill"
        }
    }
}

struct PhysicalStatsNavigationButtons: View {
    let onBack: () -> Void
    let onNext: () -> Void
    let isNextEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Back Button
            Button(action: onBack) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [.green.opacity(0.6), .green.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: .green.opacity(0.2), radius: 8, x: 0, y: 4)
                )
            }
            
            // Next Button
            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: isNextEnabled ? [.green, .mint] : [.gray, .gray],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: isNextEnabled ? .green.opacity(0.4) : .clear, radius: 12, x: 0, y: 6)
                )
            }
            .disabled(!isNextEnabled)
        }
    }
}

#Preview {
    PhysicalStatsView(coordinator: OnboardingCoordinator())
}