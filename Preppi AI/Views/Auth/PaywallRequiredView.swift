import SwiftUI
import RevenueCat
import RevenueCatUI

struct PaywallRequiredView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var revenueCatService = RevenueCatService.shared
    @State private var isCheckingEntitlements = true
    
    var body: some View {
        Group {
            if isCheckingEntitlements {
                // Show loading while checking entitlements
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Checking subscription status...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("AppBackground"))
            } else if let offering = revenueCatService.currentOffering {
                // Show RevenueCat paywall
                PaywallView(offering: offering) { customerInfo in
                    // Handle successful purchase
                    print("✅ Purchase successful in PaywallRequiredView")
                    handlePurchaseSuccess()
                    return (userCancelled: false, error: nil)
                }
                .onRestoreCompleted { customerInfo in
                    // Handle successful restore
                    print("✅ Restore successful in PaywallRequiredView")
                    if customerInfo.entitlements.active.isEmpty == false {
                        handlePurchaseSuccess()
                    }
                }
            } else {
                // Fallback UI when no offering is available
                VStack(spacing: 20) {
                    Text("Premium Required")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("To continue using Preppi AI, please upgrade to premium.")
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("AppBackground"))
            }
        }
        .onAppear {
            setupPaywall()
        }
        .onChange(of: revenueCatService.isProUser) { oldValue, newValue in
            if newValue {
                print("✅ Pro status changed to: \(newValue) - paywall will dismiss")
                handlePurchaseSuccess()
            }
        }
    }
    
    private func setupPaywall() {
        Task {
            print("🔄 PaywallRequiredView appeared - setting up RevenueCat paywall...")
            
            // First, force refresh entitlements to double-check
            print("🔍 Checking RevenueCat entitlements...")
            let hasProAccess = await revenueCatService.forceRefreshCustomerInfo()
            print("🔍 RevenueCat entitlements result: hasProAccess = \(hasProAccess)")
            
            if hasProAccess {
                print("✅ User actually has Pro access - this paywall shouldn't be showing")
                isCheckingEntitlements = false
                handlePurchaseSuccess()
                return
            }
            
            print("❌ User confirmed to not have Pro access - preparing RevenueCat paywall")
            
            // Get offerings for paywall
            await revenueCatService.fetchOfferings()
            
            await MainActor.run {
                isCheckingEntitlements = false
            }
        }
    }
    
    private func handlePurchaseSuccess() {
        appState.handlePostOnboardingPurchaseCompletion()
    }
}

#Preview {
    PaywallRequiredView()
        .environmentObject(AppState())
}
