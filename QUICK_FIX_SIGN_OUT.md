# Quick Fix: Sign Out Orphaned Session

## The Problem

Your debug log shows:
```
✅ User is authenticated: th@gmail.com
📝 No profile found in Supabase - user needs onboarding
```

You have an **orphaned authentication session** (logged in but no profile data). The app thinks you're a returning user, so it skips the `WelcomeEntryView`.

## Quick Fix Option 1: Sign Out via Settings

**If you can access Settings in the app:**

1. Open the app on your phone
2. Navigate to the Settings tab (gear icon)
3. Find "Sign Out" button
4. Tap Sign Out
5. Force close the app (swipe up from bottom, swipe app away)
6. Reopen the app
7. ✅ You should now see `WelcomeEntryView`

---

## Quick Fix Option 2: Delete App (Faster)

**Recommended for testing:**

1. On iPhone: Long-press Preppi AI app → Delete App
2. In Xcode: Product → Clean Build Folder (⇧⌘K)
3. Build and run again
4. ✅ Fresh install = new flow

---

## Quick Fix Option 3: Manual Sign Out via Code (Development)

**Add this button temporarily to any view you can access:**

```swift
Button("DEBUG: Sign Out") {
    Task {
        await AuthService.shared.signOut()
    }
}
.foregroundColor(.red)
```

Add it to `OnboardingView` or wherever you can see it, tap it, then restart the app.

---

## What Will Happen After Sign Out

After signing out and restarting, debug log will show:
```
❌ No active session: <error>
isAuthenticated: false  ← This is what we want
```

Then `ContentView` will show:
```
WelcomeEntryView (dark CalAI design) ✅
```

---

## Prevention: Why This Happened

You likely tested previously with:
1. Created account with `th@gmail.com`
2. Signed in
3. But never completed onboarding or profile creation
4. Session persisted in device keychain
5. Now you have auth but no profile (orphaned state)

---

## For Future Testing

**Clean slate every time:**
1. Delete app from device
2. Rebuild and run
3. Fresh user flow

**OR**

Always complete the full flow when testing:
1. Sign up → Complete onboarding → Create profile
2. Then test returning user flow
3. Sign out when done testing

---

## TL;DR

**Fastest Fix:**
```
1. Delete Preppi AI from iPhone
2. Xcode: Product → Clean Build Folder
3. Build & Run
4. See new WelcomeEntryView! ✨
```
