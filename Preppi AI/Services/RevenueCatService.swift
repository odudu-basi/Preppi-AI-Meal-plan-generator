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
    
    override init() {
        super.init()
        configureRevenueCat()
    }
    
    private func configureRevenueCat() {
        // Enable debug logging for troubleshooting
        Purchases.logLevel = .debug
        
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
        
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
                
                // Auto-retry for network/SSL errors after 3 seconds
                if errorMessage.contains("network") || errorMessage.contains("SSL") || errorMessage.contains("secure connection") {
                    print("🔄 Will retry in 3 seconds...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        Task {
                            print("🔄 Auto-retrying RevenueCat offerings...")
                            await self.fetchOfferings()
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
            let customerInfo = try await Purchases.shared.customerInfo()
            
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
                self.isProUser = false
            }
            print("❌ Force refresh failed: \(error)")
            return false
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