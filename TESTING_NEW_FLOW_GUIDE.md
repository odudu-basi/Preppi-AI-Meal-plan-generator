# Testing the New Onboarding Flow

## Why You're Seeing Old Flow

**Issue**: Your physical device has an **existing Supabase authentication session** from previous testing.

When the app launches:
1. `AuthService.checkAuthStatus()` runs automatically
2. Finds cached Supabase session (stored in device keychain)
3. Sets `isAuthenticated = true`
4. `ContentView` sees authenticated user
5. Skips `WelcomeEntryView` → goes to onboarding/paywall

## Solutions for Testing

### ✅ Solution 1: Delete App & Reinstall (RECOMMENDED)

This gives you a completely fresh state:

**Steps:**
1. On your iPhone, long-press the Preppi AI app
2. Tap "Remove App" → "Delete App"
3. In Xcode: **Product** → **Clean Build Folder** (⇧⌘K)
4. Build and run to your device
5. Fresh install = Fresh flow! ✨

**What you'll see:**
```
Splash Screen
    ↓
Welcome Entry Screen (NEW - dark CalAI design)
    ↓
Press "Get Started"
    ↓
Onboarding (16 screens, no auth required)
    ↓
Post-Onboarding Signup
    ↓
Paywall
    ↓
Home Screen
```

---

### ✅ Solution 2: Sign Out Programmatically

If you can access the app's Settings:

**Steps:**
1. Open app on device
2. Navigate to Settings
3. Tap "Sign Out"
4. Force close app (swipe up in app switcher)
5. Reopen app
6. Should see new `WelcomeEntryView`

---

### ✅ Solution 3: Add Debug Reset Button (For Development)

Add a quick debug helper to reset app state:

**Add to SettingsView.swift** (temporary for testing):

```swift
// In SettingsView, add this button:
Button("🔧 DEBUG: Reset to New User Flow") {
    Task {
        // Sign out
        await AuthService.shared.signOut()

        // Clear all local data
        LocalUserDataService.shared.clearAllData()
        UserDefaults.standard.removeObject(forKey: "hasSeenGetStarted")

        // Reset app state
        await MainActor.run {
            appState.isAuthenticated = false
            appState.isOnboardingComplete = false
            appState.isGuestOnboarding = false
            appState.needsSignUpAfterOnboarding = false
            appState.showSplashScreen = false
        }
    }
}
.foregroundColor(.red)
```

Then:
1. Run app
2. Go to Settings
3. Tap debug reset button
4. App resets to fresh state
5. You'll see new flow

---

### ✅ Solution 4: Clear Keychain via Simulator/Device Settings

**On Physical Device:**
1. Go to iPhone Settings (NOT app settings)
2. General → Transfer or Reset iPhone
3. Reset → Reset All Settings (doesn't delete data)
4. OR just delete the app

**On Simulator:**
1. Simulator → Device → Erase All Content and Settings
2. Restart simulator
3. Rebuild and run

---

## Testing Different Scenarios

### Scenario 1: Brand New User (Never Opened App)
**Expected Flow:**
```
Splash → WelcomeEntry → GuestOnboarding → PostSignup → Paywall → Home
```

**How to Test:**
- Delete app completely
- Reinstall
- Fresh user experience

---

### Scenario 2: Returning User (Has Account, No Subscription)
**Expected Flow:**
```
Splash → WelcomeEntry → Click "Sign In" → SignInModal → Paywall → Home
```

**How to Test:**
1. Create account through new flow
2. Close app
3. Delete app
4. Reinstall
5. Sign in with existing credentials
6. Should skip onboarding, go to paywall

---

### Scenario 3: Returning User (Has Account + Subscription)
**Expected Flow:**
```
Splash → WelcomeEntry → Click "Sign In" → SignInModal → Home (direct)
```

**How to Test:**
1. Sign in as subscriber
2. Should skip everything, go straight to home

---

### Scenario 4: User Who Started Onboarding but Didn't Finish
**Expected Flow:**
```
Splash → WelcomeEntry → GuestOnboarding (resumes)
```

**How to Test:**
This is handled automatically - onboarding data persists in memory

---

## Debugging Tools

### Check Current State

Add this to any view to see current state:

```swift
.onAppear {
    print("=== APP STATE DEBUG ===")
    print("isAuthenticated: \(appState.isAuthenticated)")
    print("isOnboardingComplete: \(appState.isOnboardingComplete)")
    print("isGuestOnboarding: \(appState.isGuestOnboarding)")
    print("needsSignUpAfterOnboarding: \(appState.needsSignUpAfterOnboarding)")
    print("hasProAccess: \(appState.hasProAccess)")
    print("======================")
}
```

### Expected Debug Output for Fresh User:

```
=== APP STATE DEBUG ===
isAuthenticated: false
isOnboardingComplete: false
isGuestOnboarding: false
needsSignUpAfterOnboarding: false
hasProAccess: false
======================
```

This should show `WelcomeEntryView`.

### What You're Currently Seeing (Authenticated):

```
=== APP STATE DEBUG ===
isAuthenticated: true  ← THIS IS THE PROBLEM
isOnboardingComplete: false
isGuestOnboarding: false
needsSignUpAfterOnboarding: false
hasProAccess: false
======================
```

This skips `WelcomeEntryView` because user is authenticated.

---

## Quick Verification Checklist

After deleting and reinstalling:

- [ ] See splash screen
- [ ] See dark WelcomeEntry screen (not old GetStarted)
- [ ] "Get Started" button visible
- [ ] "Already have an account? Sign In" visible
- [ ] Pressing "Get Started" goes to onboarding
- [ ] Can complete all 16 onboarding screens
- [ ] After onboarding, see "You're Almost There!" signup screen
- [ ] After signup, see paywall
- [ ] After subscribing, see home screen

---

## Common Issues

### Issue: Still seeing old flow after delete
**Solution**: Make sure you:
- Actually deleted the app (not just closed it)
- Cleaned build folder in Xcode
- Rebuilt from scratch

### Issue: App crashes on fresh install
**Solution**: Check Xcode console for errors - might be package issues

### Issue: Stuck on splash screen
**Solution**: Check that `showSplashScreen` is being set to `false`

---

## Production vs Development

**Development (Testing):**
- Delete app frequently to test fresh user flow
- Use debug reset buttons
- Test multiple scenarios

**Production (Real Users):**
- They will always see fresh user flow on first install
- Returning users will skip to appropriate screen
- No manual intervention needed

---

## TL;DR - Quick Reset for Testing

```bash
# On iPhone: Delete Preppi AI app
# In Xcode:
⇧⌘K (Clean Build Folder)
⌘R (Build and Run)

# Result: Fresh install, new user flow! ✨
```
