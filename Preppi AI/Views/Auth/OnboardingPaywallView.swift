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
                // Show RevenueCat paywall
                PaywallView(offering: offering) { customerInfo in
                    // Handle successful purchase
                    print("✅ Purchase successful in onboarding paywall")
                    isPurchaseCompleted = true
                    return (userCancelled: false, error: nil)
                }
                .onRestoreCompleted { customerInfo in
                    // Handle successful restore
                    print("✅ Restore successful in onboarding paywall")
                    if customerInfo.entitlements.active.isEmpty == false {
                        isPurchaseCompleted = true
                    }
                }
            } else {
                // Fallback UI when no offering is available
                VStack(spacing: 20) {
                    Text("Unlock Premium Features")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Get access to unlimited meal plans and AI-powered recipes.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button("Retry Loading") {
                        Task {
                            await revenueCatService.fetchOfferings()
                        }
                    }
                    .buttonStyle(.borderedProminent)
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