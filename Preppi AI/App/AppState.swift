import SwiftUI
import Combine
import Foundation
import RevenueCat
import Supabase

@MainActor
final class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated: Bool = false
    @Published var isOnboardingComplete: Bool = false
    @Published var userData: UserOnboardingData = UserOnboardingData()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasProAccess: Bool = false
    @Published var showPostOnboardingPaywall: Bool = false
    @Published var isCheckingEntitlements: Bool = false
    @Published var shouldDismissMealPlanFlow: Bool = false
    @Published var showSplashScreen: Bool = true
    @Published var showGetStarted: Bool = false
    @Published var selectedMealTypes: [String] = ["dinner"]
    @Published var currentMealTypeBeingCreated: String = "dinner" // Track which meal type is being created
    
    // MARK: - Services
    private let databaseService = LocalUserDataService.shared
    private let revenueCatService = RevenueCatService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupDatabaseObserver()
        setupRevenueCatObserver()
        setupAuthObserver()
        loadUserProfile()
        checkProAccess()
    }
    
    // MARK: - Setup Observers
    private func setupDatabaseObserver() {
        databaseService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        databaseService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }
    
    private func setupRevenueCatObserver() {
        revenueCatService.$isProUser
            .receive(on: DispatchQueue.main)
            .assign(to: &$hasProAccess)
    }
    
    private func setupAuthObserver() {
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAuthenticated)
        
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    // User signed in, load their profile AND check entitlements
                    self?.handleUserSignIn()
                } else {
                    // User signed out, reset all data
                    self?.resetUserData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Profile Management
    func loadUserProfile() {
        guard isAuthenticated else {
            print("👤 User not authenticated, skipping profile load")
            return
        }
        
        Task {
            do {
                print("📥 Loading user profile from local storage...")
                
                if let profileData = try await databaseService.fetchUserProfileData() {
                    self.userData = profileData.userData
                    self.isOnboardingComplete = profileData.onboardingCompleted
                    
                    if profileData.onboardingCompleted && !self.hasProAccess {
                        self.showPostOnboardingPaywall = true
                    }
                    
                    print("✅ User profile successfully loaded")
                } else {
                    self.isOnboardingComplete = false
                    print("📝 No profile found - user needs onboarding")
                }
            } catch {
                self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                print("❌ Failed to load profile: \(error)")
            }
        }
    }
    
    func completeOnboarding(with data: UserOnboardingData) async {
        do {
            print("💾 Saving user profile to Supabase...")
            // Use updateUserProfile instead of createUserProfile to save to Supabase
            try await databaseService.updateUserProfile(data)
            self.userData = data
            self.isOnboardingComplete = true
            print("✅ Profile saved successfully to Supabase")
        } catch {
            self.errorMessage = "Failed to save data: \(error.localizedDescription)"
            print("❌ Failed to save profile: \(error)")
        }
    }
    
    func updateProfile(with data: UserOnboardingData) async {
        do {
            try await databaseService.updateUserProfile(data)
            self.userData = data
        } catch {
            self.errorMessage = "Failed to update profile: \(error.localizedDescription)"
        }
    }
    
    func resetUserData() {
        isOnboardingComplete = false
        userData = UserOnboardingData()
        errorMessage = nil
        hasProAccess = false
        showPostOnboardingPaywall = false
        showGetStarted = false
        
        // Reset Get Started status so user sees it again for new account
        UserDefaults.standard.removeObject(forKey: "hasSeenGetStarted")
        
        // CRITICAL: Clear local storage data to prevent old data from persisting
        LocalUserDataService.shared.clearAllData()
        
        print("🔄 User data reset and local storage cleared")
    }
    
    func signOut() {
        Task {
            await authService.signOut()
        }
    }
    
    // MARK: - Pro Access Management
    private func checkProAccess() {
        Task {
            // Only force refresh entitlements if we haven't checked recently
            let lastCheck = UserDefaults.standard.double(forKey: "lastEntitlementCheck")
            let now = Date().timeIntervalSince1970
            
            // Check if it's been more than 5 minutes since last check
            if now - lastCheck > 300 { // 5 minutes
                print("🚀 App launched - force refreshing entitlements (last check: \(Int(now - lastCheck))s ago)...")
                await revenueCatService.forceRefreshCustomerInfo()
                await revenueCatService.fetchOfferings()
                UserDefaults.standard.set(now, forKey: "lastEntitlementCheck")
            } else {
                print("🚀 App launched - skipping entitlement refresh (checked \(Int(now - lastCheck))s ago)")
            }
        }
    }
    
    private func handleUserSignIn() {
        print("🔑 User signed in - starting profile load and entitlement check...")
        isCheckingEntitlements = true
        
        Task {
            do {
                // Add timeout to prevent infinite loading
                try await withTimeout(seconds: 30) {
                    // First, load user profile with improved sync
                    print("📥 Loading user profile...")
                    await self.loadUserProfileWithSync()
                    print("✅ Profile load complete")
                    
                    // Always check entitlements after sign in to ensure fresh data
                    print("🎟️ Force refreshing entitlements...")
                    await self.checkEntitlements()
                    print("✅ Entitlements check complete")
                }
                
                self.isCheckingEntitlements = false
                print("✅ Sign-in process completed")
                self.printUserInfo()
            } catch {
                print("❌ Sign-in process failed or timed out: \(error)")
                self.isCheckingEntitlements = false
                self.errorMessage = "Failed to load user data. Please try again."
                
                // Force show the app even if entitlements check failed
                // Better to show something than black screen
                if self.isAuthenticated && self.isOnboardingComplete {
                    print("🔄 Forcing app to show despite entitlement check failure")
                }
            }
        }
    }
    
    private func loadUserProfileWithSync() async {
        // Only load profile if user is authenticated
        guard isAuthenticated else {
            print("👤 User not authenticated, skipping profile load")
            return
        }
        
        do {
            // Try optimized sync first for better consistency
            if let syncedUserData = try? await databaseService.syncProfileData() {
                self.userData = syncedUserData
                self.isOnboardingComplete = true
                print("✅ User profile synchronized successfully")
                print("   - Name: \(syncedUserData.name)")
                print("   - Onboarding Completed: true (synced)")
                return
            }
        } catch {
            print("⚠️ Sync failed, falling back to standard load: \(error)")
        }
        
        // Fallback to the previous method if sync fails
        await loadUserProfileAsync()
    }
    
    private func loadUserProfileAsync() async {
        // Only load profile if user is authenticated
        guard isAuthenticated else {
            print("👤 User not authenticated, skipping profile load")
            return
        }
        
        do {
            // First, try to load profile from Supabase (source of truth)
            print("🔍 Checking for existing profile in Supabase...")
            
            if let supabaseUserData = try await databaseService.checkProfileExistsInSupabase() {
                // Found profile in Supabase - this is the authoritative source
                self.userData = supabaseUserData
                self.isOnboardingComplete = true  // If profile exists in Supabase, onboarding was completed
                
                print("✅ User profile successfully loaded from Supabase")
                print("   - Name: \(supabaseUserData.name)")
                print("   - Marketing Source: \(supabaseUserData.marketingSource?.rawValue ?? "None")")
                print("   - Cooking Preference: \(supabaseUserData.cookingPreference?.rawValue ?? "None")")
                print("   - Health Goals: \(supabaseUserData.healthGoals.map { $0.rawValue })")
                print("   - Weekly Budget: $\(supabaseUserData.weeklyBudget ?? 0)")
                print("   - Onboarding Completed: true (from Supabase)")
                
            } else {
                // No profile in Supabase, fallback to local storage for any cached data
                print("📱 No profile in Supabase, checking local storage as fallback...")
                
                if let profileData = try await databaseService.fetchUserProfileData() {
                    self.userData = profileData.userData
                    // Be conservative - if not in Supabase, probably need to re-complete onboarding
                    self.isOnboardingComplete = false
                    
                    print("⚠️ Found local profile but not in Supabase - may need re-onboarding")
                    print("   - Name: \(profileData.userData.name)")
                } else {
                    // No profile anywhere - fresh user
                    self.isOnboardingComplete = false
                    print("📝 No profile found anywhere - user needs to complete onboarding")
                }
            }
        } catch {
            // Error loading from Supabase, fallback to local
            print("⚠️ Error checking Supabase, falling back to local storage: \(error)")
            
            do {
                if let profileData = try await databaseService.fetchUserProfileData() {
                    self.userData = profileData.userData
                    self.isOnboardingComplete = profileData.onboardingCompleted
                    print("✅ User profile loaded from local storage (Supabase unavailable)")
                } else {
                    self.isOnboardingComplete = false
                    print("📝 No profile found locally either - user needs onboarding")
                }
            } catch {
                self.errorMessage = "Failed to load user profile: \(error.localizedDescription)"
                print("❌ Failed to load profile from any source: \(error)")
            }
        }
    }
    
    private func checkEntitlements() async {
        print("🎟️ Force refreshing RevenueCat entitlements from server...")
        
        // Force refresh customer info to get latest entitlement status
        let hasProAccess = await revenueCatService.forceRefreshCustomerInfo()
        
        // Also fetch offerings to ensure they're available for paywall
        await revenueCatService.fetchOfferings()
        
        print("🎟️ Entitlement check completed - Pro status: \(hasProAccess)")
    }
    
    func handlePostOnboardingPurchaseCompletion() {
        showPostOnboardingPaywall = false
        print("✅ Purchase completed")
    }
    
    // MARK: - Computed Properties
    // Check if user can access main app (authenticated AND completed onboarding AND has Pro access)
    var canAccessMainApp: Bool {
        isAuthenticated && isOnboardingComplete && hasProAccess
    }
    
    var shouldShowOnboarding: Bool {
        isAuthenticated && !isOnboardingComplete && !isCheckingEntitlements
    }
    
    var shouldShowPaywall: Bool {
        // Show paywall if user is authenticated, completed onboarding, but doesn't have Pro access
        // and not currently checking entitlements
        return isAuthenticated && isOnboardingComplete && !hasProAccess && !isCheckingEntitlements
    }
    
    var shouldShowGetStarted: Bool {
        !isAuthenticated && !hasSeenGetStarted && !showGetStarted
    }
    
    var shouldShowAuth: Bool {
        !isAuthenticated && (hasSeenGetStarted || showGetStarted)
    }
    
    var shouldShowLoading: Bool {
        isLoading || (isAuthenticated && isCheckingEntitlements)
    }
    
    // MARK: - Get Started Management
    private var hasSeenGetStarted: Bool {
        UserDefaults.standard.bool(forKey: "hasSeenGetStarted")
    }
    
    func markGetStartedAsSeen() {
        UserDefaults.standard.set(true, forKey: "hasSeenGetStarted")
        showGetStarted = true
    }
    
    // MARK: - Debug Methods
    func printUserInfo() {
        print("\n👤 Current User Info:")
        print("Authenticated: \(isAuthenticated)")
        print("Onboarding Complete: \(isOnboardingComplete)")
        print("Pro Access: \(hasProAccess)")
        print("Checking Entitlements: \(isCheckingEntitlements)")
        print("Has Seen Get Started: \(hasSeenGetStarted)")
        print("Show Get Started: \(shouldShowGetStarted)")
        print("Show Auth: \(shouldShowAuth)")
        print("Show Loading: \(shouldShowLoading)")
        print("Show Onboarding: \(shouldShowOnboarding)")
        print("Show Paywall: \(shouldShowPaywall)")
        print("Access Main App: \(canAccessMainApp)")
        print("User Name: \(userData.name)\n")
    }
    
    // MARK: - Helper Functions
    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

struct TimeoutError: Error {
    let localizedDescription = "Operation timed out"
}
