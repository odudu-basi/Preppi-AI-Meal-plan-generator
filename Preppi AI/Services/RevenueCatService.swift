import Foundation
import RevenueCat
import SwiftUI

class RevenueCatService: NSObject, ObservableObject {
    static let shared = RevenueCatService()
    
    @Published var isProUser = false
    @Published var currentOffering: Offering?
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiKey = "appl_mrfQufZNpGpdmPAJsnBZtNWGLKO"
    private var hasRecentlyRetried = false
    
    override init() {
        super.init()
        configureRevenueCat()
    }
    
    private func configureRevenueCat() {
        // Only enable debug logging in debug builds
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn  // Only show warnings and errors in production
        #endif
        
        // Configure RevenueCat for full subscription and paywall management
        Purchases.configure(with: .builder(withAPIKey: apiKey)
            .with(storeKitVersion: .storeKit2)
            .build()
        )
        Purchases.shared.delegate = self
        
        print("✅ RevenueCat configured for full subscription management with StoreKit 2")
        
        // Check initial entitlement status
        checkProEntitlement()
    }
    
    func fetchOfferings() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let offerings = try await Purchases.shared.offerings()
            DispatchQueue.main.async {
                // Try to get "Default_offering" specifically, fall back to current if not found
                if let defaultOffering = offerings.offering(identifier: "Default_offering") {
                    self.currentOffering = defaultOffering
                    print("✅ Found Default_offering: \(defaultOffering.identifier)")
                } else if let currentOffering = offerings.current {
                    self.currentOffering = currentOffering
                    print("✅ Using current offering: \(currentOffering.identifier)")
                } else {
                    self.currentOffering = nil
                    print("⚠️ No offerings found")
                }
                
                // Debug: Print all available offerings
                print("📋 Available offerings: \(offerings.all.keys.joined(separator: ", "))")
                
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                let errorMessage = "Failed to load offers: \(error.localizedDescription)"
                self.error = errorMessage
                self.isLoading = false
                
                // Enhanced error logging
                print("❌ RevenueCat error: \(error)")
                if let rcError = error as? RevenueCat.ErrorCode {
                    print("❌ RevenueCat error code: \(rcError)")
                }
                
                // Auto-retry for network/SSL errors after 5 seconds (limit to prevent spam)
                if (errorMessage.contains("network") || errorMessage.contains("SSL") || errorMessage.contains("secure connection")) && !self.hasRecentlyRetried {
                    print("🔄 Will retry in 5 seconds...")
                    self.hasRecentlyRetried = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        Task {
                            print("🔄 Auto-retrying RevenueCat offerings...")
                            await self.fetchOfferings()
                            // Reset retry flag after 30 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                                self.hasRecentlyRetried = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    func purchase(package: Package) async -> Bool {
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            let success = !result.userCancelled
            
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.checkProEntitlement()
                }
            }
            
            return success
        } catch {
            DispatchQueue.main.async {
                self.error = "Purchase failed: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
    
    func restorePurchases() async -> Bool {
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            _ = try await Purchases.shared.restorePurchases()
            DispatchQueue.main.async {
                self.isLoading = false
                self.checkProEntitlement()
            }
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = "Restore failed: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
    
    private func checkProEntitlement() {
        Purchases.shared.getCustomerInfo { [weak self] (customerInfo, error) in
            DispatchQueue.main.async {
                if let customerInfo = customerInfo {
                    let isProActive = customerInfo.entitlements["Pro"]?.isActive == true
                    self?.isProUser = isProActive
                    print("🔍 Pro entitlement status: \(isProActive)")
                    
                    // Debug: Print entitlement details
                    if let proEntitlement = customerInfo.entitlements["Pro"] {
                        print("🔍 Pro entitlement details:")
                        print("   - Active: \(proEntitlement.isActive)")
                        print("   - Will Renew: \(proEntitlement.willRenew)")
                        print("   - Period Type: \(proEntitlement.periodType)")
                        print("   - Expiration Date: \(proEntitlement.expirationDate?.description ?? "N/A")")
                    }
                    
                    // RevenueCat manages both subscriptions and paywall UI
                    if isProActive {
                        print("📢 Pro entitlement is active - user has premium access")
                    }
                } else {
                    self?.isProUser = false
                    print("❌ Could not check entitlements: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    // Force refresh customer info from RevenueCat servers
    func forceRefreshCustomerInfo() async -> Bool {
        print("🔄 Force refreshing customer info from RevenueCat servers...")
        
        do {
            // Add timeout to prevent hanging
            let customerInfo = try await withTimeout(seconds: 15) {
                try await Purchases.shared.customerInfo()
            }
            
            DispatchQueue.main.async {
                let isProActive = customerInfo.entitlements["Pro"]?.isActive == true
                self.isProUser = isProActive
                print("✅ Force refresh completed - Pro status: \(isProActive)")
                
                // Debug: Print fresh entitlement details
                if let proEntitlement = customerInfo.entitlements["Pro"] {
                    print("🔍 Fresh Pro entitlement details:")
                    print("   - Active: \(proEntitlement.isActive)")
                    print("   - Will Renew: \(proEntitlement.willRenew)")
                    print("   - Period Type: \(proEntitlement.periodType)")
                    print("   - Expiration Date: \(proEntitlement.expirationDate?.description ?? "N/A")")
                }
            }
            
            return customerInfo.entitlements["Pro"]?.isActive == true
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to refresh customer info: \(error.localizedDescription)"
                // Don't set isProUser = false immediately - let app show with limited access
                print("⚠️ RevenueCat check failed, allowing limited access")
            }
            print("❌ Force refresh failed: \(error)")
            
            // Return false but don't prevent app from showing
            return false
        }
    }
    
    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw RevenueCatTimeoutError()
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    func getCustomerInfo() async -> CustomerInfo? {
        do {
            return try await Purchases.shared.customerInfo()
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to get customer info: \(error.localizedDescription)"
            }
            return nil
        }
    }
}

// MARK: - PurchasesDelegate
extension RevenueCatService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        DispatchQueue.main.async {
            let isProActive = customerInfo.entitlements["Pro"]?.isActive == true
            self.isProUser = isProActive
            print("🔄 Customer info updated - Pro status: \(isProActive)")
        }
    }
}

struct RevenueCatTimeoutError: Error {
    let localizedDescription = "RevenueCat operation timed out"
}

// MARK: - RevenueCat Paywall UI Methods
extension RevenueCatService {
    
    /// Present RevenueCat's native paywall UI
    @MainActor
    func presentPaywall() async -> Bool {
        guard let currentOffering = currentOffering else {
            print("❌ No offering available for paywall")
            await fetchOfferings()
            guard let offering = currentOffering else {
                error = "No subscription options available"
                return false
            }
            return await presentPaywall(offering: offering)
        }
        
        return await presentPaywall(offering: currentOffering)
    }
    
    /// Present RevenueCat's native paywall UI with specific offering
    @MainActor
    private func presentPaywall(offering: Offering) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            // RevenueCat's PaywallView will be presented by the calling view
            print("✅ Paywall data prepared for offering: \(offering.identifier)")
            isLoading = false
            return true
        } catch {
            self.error = "Failed to prepare paywall: \(error.localizedDescription)"
            isLoading = false
            print("❌ Paywall preparation failed: \(error)")
            return false
        }
    }
}
