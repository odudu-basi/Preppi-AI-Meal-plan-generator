import SwiftUI
import RevenueCat
import RevenueCatUI

struct PaywallRequiredView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var revenueCatService = RevenueCatService.shared
    
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
                            // Purchase completed, user can now access main app
                            print("✅ Purchase completed in PaywallRequiredView")
                        }
                    }
                    .onRestoreCompleted { customerInfo in
                        // Check if pro entitlement is active after restore
                        if customerInfo.entitlements["Pro"]?.isActive == true {
                            print("✅ Restore completed in PaywallRequiredView")
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
            // Force refresh entitlements when paywall appears
            Task {
                print("🔄 PaywallRequiredView appeared - force refreshing entitlements...")
                let hasProAccess = await revenueCatService.forceRefreshCustomerInfo()
                
                if hasProAccess {
                    print("✅ User actually has Pro access - this paywall shouldn't be showing")
                    // User has Pro access, this view should not be visible
                    return
                } else {
                    print("❌ User confirmed to not have Pro access - showing paywall")
                    // Ensure offerings are loaded for paywall
                    await revenueCatService.fetchOfferings()
                }
            }
        }
        .onChange(of: revenueCatService.isProUser) { oldValue, newValue in
            if newValue {
                // User purchased Pro, AppState will handle the transition
                print("✅ Pro status changed to: \(newValue)")
            }
        }
    }
}

#Preview {
    PaywallRequiredView()
        .environmentObject(AppState())
}