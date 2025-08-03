import SwiftUI
import RevenueCat
import RevenueCatUI

struct OnboardingPaywallView: View {
    @StateObject private var revenueCatService = RevenueCatService.shared
    @Binding var isPurchaseCompleted: Bool
    
    var body: some View {
        Group {
            if revenueCatService.isLoading {
                // Loading state
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading subscription options...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
            } else if let offering = revenueCatService.currentOffering {
                // Show ONLY your RevenueCat paywall - no custom UI
                RevenueCatUI.PaywallView(offering: offering)
                    .onPurchaseCompleted { customerInfo in
                        // Check if pro entitlement is active after purchase
                        if customerInfo.entitlements["Pro"]?.isActive == true {
                            isPurchaseCompleted = true
                        }
                    }
                    .onRestoreCompleted { customerInfo in
                        // Check if pro entitlement is active after restore
                        if customerInfo.entitlements["Pro"]?.isActive == true {
                            isPurchaseCompleted = true
                        }
                    }
            } else {
                // If no offering is available, show retry
                VStack(spacing: 20) {
                    Text("Unable to load subscription options")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Please check your internet connection and try again")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        Task {
                            await revenueCatService.fetchOfferings()
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.green)
                    .cornerRadius(25)
                    .padding(.horizontal)
                }
                .padding()
            }
            
            if let error = revenueCatService.error {
                VStack {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Retry") {
                        Task {
                            await revenueCatService.fetchOfferings()
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.green)
                    .cornerRadius(25)
                    .padding(.horizontal)
                }
            }
        }
        .interactiveDismissDisabled(true) // Prevent swipe to dismiss
        .onAppear {
            Task {
                // Force refresh entitlements first, then get offerings
                print("🔄 OnboardingPaywallView appeared - checking entitlements...")
                let hasProAccess = await revenueCatService.forceRefreshCustomerInfo()
                
                if hasProAccess {
                    print("✅ User already has Pro during onboarding paywall")
                    isPurchaseCompleted = true
                    return
                }
                
                // Get offerings for paywall
                await revenueCatService.fetchOfferings()
            }
        }
        .onChange(of: revenueCatService.isProUser) { oldValue, newValue in
            if newValue {
                isPurchaseCompleted = true
            }
        }
    }
}



#Preview {
    OnboardingPaywallView(isPurchaseCompleted: .constant(false))
}