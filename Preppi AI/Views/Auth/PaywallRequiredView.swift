import SwiftUI
import RevenueCat
import SuperwallKit

struct PaywallRequiredView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var revenueCatService = RevenueCatService.shared
    @StateObject private var superwallService = SuperwallService.shared
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
            } else {
                // Show Superwall paywall or fallback
                VStack(spacing: 20) {
                    Text("Premium Required")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("To continue using Preppi AI, please upgrade to premium.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button("View Plans") {
                        presentSuperwall()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("AppBackground"))
                .onAppear {
                    // Auto-present Superwall when view appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        presentSuperwall()
                    }
                }
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
            
            print("❌ User confirmed to not have Pro access - preparing Superwall paywall")
            
            await MainActor.run {
                isCheckingEntitlements = false
            }
        }
    }
    
    private func presentSuperwall() {
        print("🎯 Presenting Superwall paywall...")
        
        SuperwallService.shared.presentPaywall(
            for: "campaign_trigger",
            parameters: [
                "source": "paywall_required",
                "user_type": "existing"
            ]
        )
    }
    
    private func handlePurchaseSuccess() {
        appState.handlePostOnboardingPurchaseCompletion()
    }
}

#Preview {
    PaywallRequiredView()
        .environmentObject(AppState())
}
