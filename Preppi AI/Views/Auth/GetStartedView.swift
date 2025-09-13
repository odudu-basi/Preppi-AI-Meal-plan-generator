import SwiftUI

struct GetStartedView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingSignIn = false
    @State private var showingSignUp = false
    @State private var animationTrigger = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Replace image with gradient background
                LinearGradient(
                    colors: [Color.green, Color.mint],
                    startPoint: .top,
                    endPoint: .bottom
                )
                    .ignoresSafeArea()
                
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                // Main content centered
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Add welcome message above logo
                    Text("Welcome to")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Add animation to logo text
                    Text("PREPPI AI")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(4)
                        .opacity(animationTrigger ? 1 : 0)
                        .animation(.easeIn(duration: 1.0), value: animationTrigger)
                    
                    // Simplified logo section without image and animations
                    VStack(spacing: 12) {
                        Text("Your AI-Powered Meal Planning Companion")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Simplified action buttons
                    VStack(spacing: 16) {
                        Button {
                            appState.markGetStartedAsSeen()
                            showingSignUp = true
                        } label: {
                            Text("Start Your Journey")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.2), radius: 5)
                        }
                        
                        Button {
                            appState.markGetStartedAsSeen()
                            showingSignIn = true
                        } label: {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                    
                    Spacer()
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
        .onAppear {
            animationTrigger = true
        }
    }
    
    // MARK: - Logo Section
    private var logoSection: some View {
        VStack(spacing: 24) {
            // Animated app icon
            ZStack {
                // Glowing background
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 160, height: 160)
                    .blur(radius: 10)
                    .scaleEffect(1.1)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animationTrigger)
                
                // App icon
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .opacity(0.5)
                    )
                    .shadow(color: .white.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            
            VStack(spacing: 12) {
                // App name with gradient
                Text("PREPPI AI")
                    .font(.system(size: 42, weight: .heavy, design: .default))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .tracking(3)
                
                // Animated tagline
                Text("Your AI-Powered Meal Planning Companion")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .opacity(0.9)
                    .transition(.opacity)
                    .animation(.easeIn(duration: 1.0), value: animationTrigger)
            }
        }
        .padding(.bottom, 50)
    }
    
    // MARK: - Features Carousel
    private var featuresCarousel: some View {
        VStack(spacing: 24) {
            // Section header
            VStack(spacing: 8) {
                Text("Discover Preppi AI")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Revolutionize your meal planning")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 16)
            
            // Carousel of features
            TabView {
                FeatureCard(
                    icon: "brain",
                    iconColor: .purple,
                    title: "Smart Meal Plans",
                    description: "AI-generated weekly plans tailored to your goals and preferences"
                )
                
                FeatureCard(
                    icon: "cart.fill",
                    iconColor: .blue,
                    title: "Intelligent Shopping",
                    description: "Auto-generated lists with smart organization and reminders"
                )
                
                FeatureCard(
                    icon: "book.closed.fill",
                    iconColor: .orange,
                    title: "Recipe Library",
                    description: "Detailed recipes with step-by-step guidance and nutrition info"
                )
                
                FeatureCard(
                    icon: "chart.bar.fill",
                    iconColor: .red,
                    title: "Progress Tracking",
                    description: "Track macros, calories, and health goals effortlessly"
                )
                
                FeatureCard(
                    icon: "photo.fill",
                    iconColor: .green,
                    title: "Visual Inspiration",
                    description: "AI-generated meal images to motivate your cooking"
                )
            }
            .tabViewStyle(PageTabViewStyle())
            .frame(height: 180)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
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
                Text("Start Your Journey")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Color.white
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .white.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Sign In Link
            VStack(spacing: 12) {
                Text("Already a member?")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Button {
                    appState.markGetStartedAsSeen()
                    showingSignIn = true
                } label: {
                    Text("Sign In")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 2)
                                .background(Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Feature Card Component
struct FeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundColor(iconColor)
            
            // Title
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Description
            Text(description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    GetStartedView()
        .environmentObject(AppState())
}