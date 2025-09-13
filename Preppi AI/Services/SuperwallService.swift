import Foundation
import SwiftUI
import SuperwallKit
import RevenueCat

class SuperwallService: ObservableObject {
    static let shared = SuperwallService()
    
    @Published var isConfigured = false
    
    private let apiKey = "pk_796843e739b0b13d93cc0fb8df0361ba17b5ba9657e588c1"
    
    private init() {
        configure()
    }
    
    func configure() {
        // Configure Superwall with basic setup
        Superwall.configure(apiKey: apiKey)
        
        // Set delegate for handling events
        Superwall.shared.delegate = self
        
        print("✅ Superwall configured with API key: \(String(apiKey.prefix(8)))...")
        
        DispatchQueue.main.async {
            self.isConfigured = true
        }
    }
    
    // MARK: - Paywall Methods
    
    /// Present paywall for a specific placement
    func presentPaywall(for placement: String = "campaign_trigger") {
        print("🎯 Presenting Superwall paywall for placement: \(placement)")
        Superwall.shared.register(placement: placement)
    }
    
    /// Present paywall with custom parameters
    func presentPaywall(for placement: String, parameters: [String: Any]? = nil) {
        print("🎯 Presenting Superwall paywall for placement: \(placement)")
        print("📊 Parameters: \(parameters ?? [:])")
        
        if let parameters = parameters {
            Superwall.shared.register(placement: placement, params: parameters)
        } else {
            Superwall.shared.register(placement: placement)
        }
    }
    
    /// Check if user has active subscription
    func hasActiveSubscription() -> Bool {
        return RevenueCatService.shared.isProUser
    }
    
    // MARK: - User Identity
    
    /// Set user ID for Superwall analytics
    func setUserId(_ userId: String) {
        Superwall.shared.setUserAttributes(["user_id": userId])
        print("👤 Superwall user ID set: \(userId)")
    }
    
    /// Set user attributes for targeting
    func setUserAttributes(_ attributes: [String: Any]) {
        Superwall.shared.setUserAttributes(attributes)
        print("👤 Superwall user attributes set: \(attributes)")
    }
    
    // MARK: - Analytics
    
    /// Track custom event
    func track(event: String, parameters: [String: Any]? = nil) {
        if let parameters = parameters {
            Superwall.shared.register(placement: event, params: parameters)
        } else {
            Superwall.shared.register(placement: event)
        }
        print("📊 Superwall event tracked: \(event)")
    }
}

// MARK: - SuperwallDelegate

extension SuperwallService: SuperwallDelegate {
    func handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo) {
        switch eventInfo.event {
        case .firstSeen:
            print("🎯 Superwall: First seen")
            
        case .appOpen:
            print("🎯 Superwall: App opened")
            
        case .appClose:
            print("🎯 Superwall: App closed")
            
        case .appInstall:
            print("🎯 Superwall: App installed")
            
        case .sessionStart:
            print("🎯 Superwall: Session started")
            
        case .deviceAttributes(let attributes):
            print("🎯 Superwall: Device attributes - \(attributes)")
            
        case .subscriptionStatusDidChange:
            print("🎯 Superwall: Subscription status changed")
            
        case .paywallOpen(let paywallInfo):
            print("🎯 Superwall: Paywall opened - \(paywallInfo.name)")
            
        case .paywallClose(let paywallInfo):
            print("🎯 Superwall: Paywall closed - \(paywallInfo.name)")
            
        case .transactionStart(let product, let paywallInfo):
            print("🎯 Superwall: Transaction started - \(product.productIdentifier) from paywall \(paywallInfo.name)")
            
        case .transactionFail(let error, let paywallInfo):
            print("🎯 Superwall: Transaction failed - \(error) from paywall \(paywallInfo.name)")
            
        case .transactionAbandon(let product, let paywallInfo):
            print("🎯 Superwall: Transaction abandoned - \(product.productIdentifier) from paywall \(paywallInfo.name)")
            
        case .transactionComplete(let transaction, let product, let type, let paywallInfo):
            print("🎯 Superwall: Transaction completed - \(product.productIdentifier) from paywall \(paywallInfo.name)")
            
        case .subscriptionStart(let product, let paywallInfo):
            print("🎯 Superwall: Subscription started - \(product.productIdentifier) from paywall \(paywallInfo.name)")
            
        case .freeTrialStart(let product, let paywallInfo):
            print("🎯 Superwall: Free trial started - \(product.productIdentifier) from paywall \(paywallInfo.name)")
            
        case .nonRecurringProductPurchase(let product, let paywallInfo):
            print("🎯 Superwall: Non-recurring purchase - \(product.id) from paywall \(paywallInfo.name)")
            
        case .paywallResponseLoadStart:
            print("🎯 Superwall: Paywall response load started")
            
        case .paywallResponseLoadNotFound:
            print("🎯 Superwall: Paywall response not found")
            
        case .paywallResponseLoadFail(let error):
            print("🎯 Superwall: Paywall response load failed - \(error)")
            
        case .paywallResponseLoadComplete:
            print("🎯 Superwall: Paywall response load completed")
            
        case .paywallWebviewLoadStart:
            print("🎯 Superwall: Paywall webview load started")
            
        case .paywallWebviewLoadFail(let error):
            print("🎯 Superwall: Paywall webview load failed - \(error)")
            
        case .paywallWebviewLoadComplete:
            print("🎯 Superwall: Paywall webview load completed")
            
        case .paywallWebviewLoadTimeout:
            print("🎯 Superwall: Paywall webview load timeout")
            
        case .paywallProductsLoadStart:
            print("🎯 Superwall: Paywall products load started")
            
        case .paywallProductsLoadFail(let error):
            print("🎯 Superwall: Paywall products load failed - \(error)")
            
        case .paywallProductsLoadComplete:
            print("🎯 Superwall: Paywall products load completed")
            
        case .reset:
            print("🎯 Superwall: Reset")
            
        @unknown default:
            print("🎯 Superwall: Unknown event - \(eventInfo.event)")
        }
    }
    
    func handleCustomPaywallAction(withName name: String) {
        print("🎯 Superwall: Custom paywall action - \(name)")
        
        // Handle custom actions from your paywall
        switch name {
        case "close_paywall":
            // Handle close action
            break
        case "contact_support":
            // Handle support action
            break
        default:
            break
        }
    }
}
