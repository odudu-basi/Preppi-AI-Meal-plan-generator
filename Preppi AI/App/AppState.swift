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
            // Force refresh entitlements on app launch
            print("🚀 App launched - force refreshing entitlements...")
            await revenueCatService.forceRefreshCustomerInfo()
            await revenueCatService.fetchOfferings()
        }
    }
    
    private func handleUserSignIn() {
        print("🔑 User signed in - loading profile and checking entitlements...")
        isCheckingEntitlements = true
        
        Task {
            // First, load user profile with improved sync
            await loadUserProfileWithSync()
            
            // Always check entitlements after sign in to ensure fresh data
            print("✅ Profile loaded, force refreshing entitlements from RevenueCat...")
            await checkEntitlements()
            
            self.isCheckingEntitlements = false
            print("✅ Sign-in process completed")
            self.printUserInfo()
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
        isAuthenticated && isOnboardingComplete && !hasProAccess && !isCheckingEntitlements
    }
    
    var shouldShowAuth: Bool {
        !isAuthenticated
    }
    
    var shouldShowLoading: Bool {
        isLoading || (isAuthenticated && isCheckingEntitlements)
    }
    
    // MARK: - Debug Methods
    func printUserInfo() {
        print("\n👤 Current User Info:")
        print("Authenticated: \(isAuthenticated)")
        print("Onboarding Complete: \(isOnboardingComplete)")
        print("Pro Access: \(hasProAccess)")
        print("Checking Entitlements: \(isCheckingEntitlements)")
        print("Show Auth: \(shouldShowAuth)")
        print("Show Loading: \(shouldShowLoading)")
        print("Show Onboarding: \(shouldShowOnboarding)")
        print("Show Paywall: \(shouldShowPaywall)")
        print("Access Main App: \(canAccessMainApp)")
        print("User Name: \(userData.name)\n")
    }
}
