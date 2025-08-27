import SwiftUI

struct GetStartedView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingSignIn = false
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient matching app design
                LinearGradient(
                    colors: [
                        Color("AppBackground"),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top spacing
                        Spacer()
                            .frame(height: 60)
                        
                        // App logo and title section
                        logoSection
                        
                        // Features list section
                        featuresSection
                        
                        // Action buttons section
                        actionButtonsSection
                        
                        // Bottom spacing
                        Spacer()
                            .frame(height: 60)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingSignUp) {
            SignInSignUpView(initialMode: .signUp)
                .environmentObject(appState)
        }
        .fullScreenCover(isPresented: $showingSignIn) {
            SignInSignUpView(initialMode: .signIn)
                .environmentObject(appState)
        }
    }
    
    // MARK: - Logo Section
    private var logoSection: some View {
        VStack(spacing: 24) {
            // App icon with shadow
            ZStack {
                // Shadow background
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 144, height: 144)
                    .offset(x: 3, y: 3)
                
                // App icon
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            }
            
            VStack(spacing: 12) {
                // App name
                Text("PREPPI AI")
                    .font(.system(size: 42, weight: .heavy, design: .default))
                    .foregroundColor(.green)
                    .tracking(3)
                
                // Tagline
                Text("Your AI-Powered Meal Planning Assistant")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 50)
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 24) {
            // Section header
            VStack(spacing: 8) {
                Text("Everything You Need")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Plan, shop, and cook with confidence")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 16)
            
            // Features list
            VStack(spacing: 20) {
                FeatureRow(
                    icon: "brain",
                    iconColor: .purple,
                    title: "AI-Generated Meal Plans",
                    description: "Personalized weekly meal plans tailored to your preferences, goals, and dietary needs"
                )
                
                FeatureRow(
                    icon: "cart.fill",
                    iconColor: .blue,
                    title: "Smart Shopping Lists",
                    description: "Automatically generated shopping lists organized by category to streamline your grocery trips"
                )
                
                FeatureRow(
                    icon: "book.closed.fill",
                    iconColor: .orange,
                    title: "Detailed Recipes",
                    description: "Step-by-step cooking instructions with ingredient lists and nutritional information"
                )
                
                FeatureRow(
                    icon: "chart.bar.fill",
                    iconColor: .red,
                    title: "Nutrition Tracking",
                    description: "Track your daily macros and calories to stay aligned with your health goals"
                )
                
                FeatureRow(
                    icon: "photo.fill",
                    iconColor: .green,
                    title: "Meal Visualization",
                    description: "AI-generated images of your meals to see exactly what you'll be cooking"
                )
            }
        }
        .padding(.bottom, 60)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 24) {
            // Get Started Button
            Button {
                appState.markGetStartedAsSeen()
                showingSignUp = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Get Started")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .green.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Sign In Link
            VStack(spacing: 12) {
                Text("Already have an account?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button {
                    appState.markGetStartedAsSeen()
                    showingSignIn = true
                } label: {
                    Text("Sign In")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green, lineWidth: 2)
                                .background(Color(.systemBackground))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    GetStartedView()
        .environmentObject(AppState())
}