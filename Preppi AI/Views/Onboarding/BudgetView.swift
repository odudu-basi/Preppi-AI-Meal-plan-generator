 
//  BudgetView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI
import RevenueCat

struct BudgetView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var customBudget = ""
    @State private var showCustomInput = false
    @State private var animateHeader = false
    @State private var animateContent = false
    @FocusState private var isCustomFieldFocused: Bool
    
    let budgetOptions = [50, 75, 100, 150, 200, 300]
    
    var body: some View {
        OnboardingContainer {
            VStack(spacing: 20) {
                // Progress indicator
                OnboardingNavigationBar(
                    currentStep: 9,
                    totalSteps: OnboardingStep.totalSteps,
                    canGoBack: true,
                    onBackTapped: {
                        coordinator.previousStep()
                    }
                )
                
                // Premium Header Section
                VStack(spacing: 25) {
                    // Animated icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.1), .yellow.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                            .opacity(animateHeader ? 1.0 : 0.0)
                        
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 45))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateHeader ? 1.0 : 0.8)
                    }
                    
                    VStack(spacing: 15) {
                        Text("Weekly Grocery Budget")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, .green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 20)
                            .opacity(animateHeader ? 1.0 : 0.0)
                            .offset(y: animateHeader ? 0 : 20)
                        
                        Text("What's your typical weekly grocery budget?")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 20)
                            .opacity(animateHeader ? 1.0 : 0.0)
                            .offset(y: animateHeader ? 0 : 20)
                    }
                }
                .padding(.top, 10)
                
                // Premium Budget Options Section
                VStack(spacing: 20) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(Array(budgetOptions.enumerated()), id: \.element) { index, budget in
                            PremiumBudgetCard(
                                amount: budget,
                                isSelected: coordinator.userData.weeklyBudget == Double(budget),
                                animateContent: animateContent,
                                index: index
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    coordinator.userData.weeklyBudget = Double(budget)
                                    showCustomInput = false
                                    customBudget = ""
                                    isCustomFieldFocused = false
                                }
                            }
                        }
                    }
                    
                    // Premium Custom Budget Option
                    PremiumCustomBudgetCard(
                        showCustomInput: $showCustomInput,
                        customBudget: $customBudget,
                        isCustomFieldFocused: $isCustomFieldFocused,
                        animateContent: animateContent,
                        onToggle: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showCustomInput.toggle()
                                if !showCustomInput {
                                    coordinator.userData.weeklyBudget = nil
                                    customBudget = ""
                                    isCustomFieldFocused = false
                                } else {
                                    // Focus the custom field after a short delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        isCustomFieldFocused = true
                                    }
                                }
                            }
                        },
                        onCustomBudgetChange: { newValue in
                            if let budgetValue = Double(newValue), budgetValue > 0 {
                                coordinator.userData.weeklyBudget = budgetValue
                            } else {
                                coordinator.userData.weeklyBudget = nil
                            }
                        }
                    )
                }
                .padding(.horizontal, 20)
                
                // Premium Complete Button and Status Messages
                VStack(spacing: 15) {
                    PremiumCompleteButton(
                        isEnabled: coordinator.userData.weeklyBudget != nil && !coordinator.isSaving,
                        isSaving: coordinator.isSaving,
                        animateContent: animateContent
                    ) {
                        coordinator.completeOnboarding()
                    }
                    
                    // Error message with retry option
                    if let error = coordinator.saveError {
                        VStack(spacing: 12) {
                            Text(error)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            
                            Button("Retry Saving to Database") {
                                coordinator.retrySave()
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    
                    // Success message for database save
                    if coordinator.isOnboardingComplete && !coordinator.isSaving {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                            Text("Profile saved successfully!")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateHeader = true
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateContent = true
            }
        }
        .sheet(isPresented: $coordinator.showPaywall) {
            OnboardingPaywallView(isPurchaseCompleted: $coordinator.isPurchaseCompleted)
                .interactiveDismissDisabled(true)
        }
        .onChange(of: coordinator.isPurchaseCompleted) { oldValue, newValue in
            if newValue {
                coordinator.handlePurchaseCompletion()
            }
        }
    }
}

// MARK: - Premium Components

struct PremiumBudgetCard: View {
    let amount: Int
    let isSelected: Bool
    let animateContent: Bool
    let index: Int
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text("$\(amount)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .green)
                
                Text("per week")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? 
                          LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color(.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? 
                                    LinearGradient(colors: [Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Color(.systemGray4).opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 1
                            )
                    )
                    .shadow(color: isSelected ? .green.opacity(0.3) : .black.opacity(0.05), 
                           radius: isSelected ? 12 : 6, 
                           x: 0, 
                           y: isSelected ? 6 : 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(animateContent ? 1.0 : 0.0)
            .offset(y: animateContent ? 0 : 30)
            .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: animateContent)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct PremiumCustomBudgetCard: View {
    @Binding var showCustomInput: Bool
    @Binding var customBudget: String
    @FocusState.Binding var isCustomFieldFocused: Bool
    let animateContent: Bool
    let onToggle: () -> Void
    let onCustomBudgetChange: (String) -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Custom Budget Toggle Button
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(showCustomInput ? .white : .green)
                    
                    Text("Custom Amount")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(showCustomInput ? .white : .green)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(showCustomInput ? 
                              LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(colors: [Color(.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(showCustomInput ? 
                                        LinearGradient(colors: [Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                        LinearGradient(colors: [.green.opacity(0.6), .green.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: 2
                                )
                        )
                        .shadow(color: showCustomInput ? .green.opacity(0.3) : .green.opacity(0.1), 
                               radius: showCustomInput ? 12 : 6, 
                               x: 0, 
                               y: showCustomInput ? 6 : 2)
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }, perform: {})
            
            // Custom Input Field (when expanded)
            if showCustomInput {
                HStack(spacing: 15) {
                    Text("$")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.green)
                    
                    TextField("Enter amount", text: $customBudget)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 18, weight: .medium))
                        .focused($isCustomFieldFocused)
                        .onChange(of: customBudget) { oldValue, newValue in
                            onCustomBudgetChange(newValue)
                        }
                    
                    Text("per week")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isCustomFieldFocused ?
                                    LinearGradient(colors: [.green.opacity(0.6), .green.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Color(.systemGray4).opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: isCustomFieldFocused ? 2 : 1
                                )
                        )
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.easeOut(duration: 0.6).delay(0.6), value: animateContent)
    }
}

struct PremiumCompleteButton: View {
    let isEnabled: Bool
    let isSaving: Bool
    let animateContent: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.9)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                Text(isSaving ? "Saving..." : "Complete Onboarding")
                    .font(.system(size: 18, weight: .semibold))
                
                if !isSaving {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isEnabled ? [.green, .mint] : [.gray.opacity(0.6), .gray.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isEnabled ? .green.opacity(0.4) : .clear,
                        radius: isEnabled ? 12 : 0,
                        x: 0,
                        y: 6
                    )
            )
        }
        .disabled(!isEnabled)
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BudgetView(coordinator: OnboardingCoordinator())
}