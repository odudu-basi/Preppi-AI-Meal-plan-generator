//
//  ContentView.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 7/25/25.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct PreppiLogo: View {
    var body: some View {
        VStack(spacing: 20) {
            // App Icon
            ZStack {
                // Shadow background
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 124, height: 124)
                    .offset(x: 2, y: 2)
                
                // App icon with rounded corners
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            
            // PREPPI text
            Text("PREPPI")
                .font(.system(size: 36, weight: .heavy, design: .default))
                .foregroundColor(.green)
                .tracking(4)
        }
    }
}

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        Group {
            if appState.showSplashScreen {
                // Show splash screen only on initial app launch
                SplashScreenView {
                    appState.showSplashScreen = false
                }
            } else if appState.shouldShowAuth {
                // Show authentication if not signed in
                SignInSignUpView()
                    .environmentObject(appState)
            } else if appState.shouldShowLoading {
                // Show loading state for general app loading or checking entitlements
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(appState.isCheckingEntitlements ? "Verifying subscription..." : "Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else if appState.shouldShowOnboarding {
                // Show onboarding if authenticated but not onboarded
                OnboardingView()
                    .environmentObject(appState)
            } else if appState.shouldShowPaywall {
                // Show paywall if authenticated and onboarded but no Pro access
                PaywallRequiredView()
                    .environmentObject(appState)
            } else if appState.canAccessMainApp {
                // Show main app if authenticated, onboarded, and has Pro access
                MainScreenView()
                    .environmentObject(appState)
            } else {
                // Fallback loading state
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: appState.isOnboardingComplete)
        .animation(.easeInOut(duration: 0.4), value: appState.hasProAccess)
        .animation(.easeInOut(duration: 0.4), value: appState.isCheckingEntitlements)
        .onAppear {
            // Debug: Print current user info
            appState.printUserInfo()
        }
    }
}

struct MainScreenView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingProfile = false
    @State private var showingFounderUpdates = false
    @State private var navigationPath = NavigationPath()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background gradient - adaptive for light/dark mode
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .light ? 
                        [Color.white, Color(.systemGray6)] : 
                        [Color.black, Color.green]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Custom Logo
                    PreppiLogo()
                    
                    Text("Your AI-powered meal companion")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .light ? Color(.systemGray) : .secondary)
                    
                    // Welcome message with user's name
                    if !appState.userData.name.isEmpty {
                        Text("Welcome back, \(appState.userData.name)!")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 20) {
                        Button {
                            navigationPath.append("MealPlanInfo")
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Make Meals")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.green)
                                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                        }
                        
                        NavigationLink(destination: ViewMealPlansView().environmentObject(appState)) {
                            HStack {
                                Image(systemName: "list.bullet.circle.fill")
                                    .font(.title2)
                                Text("View Meals")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.9))
                                    .stroke(Color.green, lineWidth: 2)
                                    
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Settings/Profile buttons
                    VStack(spacing: 12) {

                        

                    }
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingFounderUpdates = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundColor(colorScheme == .light ? Color(.label) : .green)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: "person.circle")
                            .font(.title2)
                            .foregroundColor(colorScheme == .light ? Color(.label) : .green)
                    }
                }
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "MealPlanInfo":
                    MealPlanInfoView()
                        .environmentObject(appState)
                default:
                    EmptyView()
                }
            }
            .onChange(of: appState.shouldDismissMealPlanFlow) { shouldDismiss in
                if shouldDismiss {
                    // Clear the navigation path to return to main screen
                    navigationPath = NavigationPath()
                    // Reset the flag
                    appState.shouldDismissMealPlanFlow = false
                }
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileMenuView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingFounderUpdates) {
            FounderUpdatesView()
        }
    }
}

// MARK: - Founder Updates View
struct FounderUpdatesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "megaphone.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        Text("Updates from the founder")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Stay up to date with the latest features and improvements")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Content section
                VStack(alignment: .leading, spacing: 16) {
                    UpdateMessageCard(
                        icon: "lightbulb.fill",
                        title: "Feature Requests",
                        message: "To request features, go to feature requests on your profile menu",
                        iconColor: .orange
                    )
                    
                    UpdateMessageCard(
                        icon: "sunrise.fill",
                        title: "Breakfast and Lunch",
                        message: "Breakfast and lunch options are coming soon.",
                        iconColor: .blue
                    )
                    
                    UpdateMessageCard(
                        icon: "flame.fill",
                        title: "Streaks",
                        message: "Streaks are coming soon, stay tuned!",
                        iconColor: .orange
                    )
                    
                    UpdateMessageCard(
                        icon: "heart.fill",
                        title: "Thank You",
                        message: "Thank you for using Preppi AI! Your feedback helps us improve.",
                        iconColor: .red
                    )
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                }
            }
        }
    }
}

// MARK: - Update Message Card Component
struct UpdateMessageCard: View {
    let icon: String
    let title: String
    let message: String
    let iconColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [iconColor, iconColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    ContentView()
}
