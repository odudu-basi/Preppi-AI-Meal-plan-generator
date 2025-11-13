# Old Files - Deletion Plan

## Files That Can Be Safely Deleted

After implementing the new onboarding flow, the following files are **no longer used** in the app:

### 1. GetStartedView.swift
- **Location**: `/Views/Auth/GetStartedView.swift`
- **Status**: ❌ Not used anymore
- **Replaced by**: `WelcomeEntryView.swift`
- **Why safe to delete**:
  - Not imported or referenced anywhere except its own file
  - All references in `ContentView` have been removed
  - `shouldShowGetStarted` computed property in `AppState` is no longer checked

### 2. SignInSignUpView.swift
- **Location**: `/Views/Auth/SignInSignUpView.swift`
- **Status**: ❌ Not used anymore
- **Replaced by**:
  - `SignInOnlyView.swift` (for sign in)
  - `PostOnboardingSignUpView.swift` (for sign up after onboarding)
- **Why safe to delete**:
  - No longer imported or referenced in any view
  - The dual-mode auth view is split into two separate flows
  - All navigation logic updated in `ContentView`

## Deletion Recommendations

### Option 1: Delete Immediately ✅ (Recommended after testing)
If you've tested the new flow and everything works:

```bash
# Navigate to your project directory
cd "/Users/oduduabasivictor/Desktop/Preppi AI/Preppi AI"

# Delete the old files
rm "Views/Auth/GetStartedView.swift"
rm "Views/Auth/SignInSignUpView.swift"

# Clean up any references in Xcode
# Open Xcode → Remove file references if they still show up
```

### Option 2: Move to Archive (Safer) 📦
Keep them as backup for a week or two:

```bash
# Create archive folder
mkdir -p "/Users/oduduabasivictor/Desktop/Preppi AI/Archived_Old_Flow"

# Move files to archive
mv "Views/Auth/GetStartedView.swift" "/Users/oduduabasivictor/Desktop/Preppi AI/Archived_Old_Flow/"
mv "Views/Auth/SignInSignUpView.swift" "/Users/oduduabasivictor/Desktop/Preppi AI/Archived_Old_Flow/"
```

### Option 3: Keep Temporarily (Most Cautious) 🔒
If you want to be extra careful:
- Keep the files for 1-2 weeks while you test production
- Add a comment at the top: `// DEPRECATED - Replaced by WelcomeEntryView.swift`
- Delete after confirming no issues

## Files That Should NOT Be Deleted

Keep these - they're still used:

✅ **AuthTextField** (in `SignInSignUpView.swift`)
- Still used by `SignInOnlyView` and `PostOnboardingSignUpView`
- **ACTION NEEDED**: Extract to separate file before deleting `SignInSignUpView.swift`

✅ **AuthPasswordField** (in `SignInSignUpView.swift`)
- Still used by `SignInOnlyView` and `PostOnboardingSignUpView`
- **ACTION NEEDED**: Extract to separate file before deleting `SignInSignUpView.swift`

✅ **ForgotPasswordView** (in `SignInSignUpView.swift`)
- Still used by `SignInOnlyView`
- **ACTION NEEDED**: Extract to separate file before deleting `SignInSignUpView.swift`

## IMPORTANT: Extract Shared Components First!

Before deleting `SignInSignUpView.swift`, we need to move the shared components to a new file:

### Create: `Views/Auth/AuthComponents.swift`

Move these components from `SignInSignUpView.swift`:
- `AuthTextField`
- `AuthPasswordField`
- `ForgotPasswordView`

This allows us to safely delete `SignInSignUpView.swift` without losing reusable code.

## Action Plan (Recommended Order)

1. ✅ **Test the new flow thoroughly**
   - New user signup flow
   - Returning user sign-in
   - Profile saves correctly
   - Paywall shows appropriately

2. ✅ **Extract shared components** (see below)
   - Create `AuthComponents.swift`
   - Move `AuthTextField`, `AuthPasswordField`, `ForgotPasswordView`
   - Update imports in `SignInOnlyView` and `PostOnboardingSignUpView`

3. ✅ **Delete old files**
   - `GetStartedView.swift` - Safe to delete immediately
   - `SignInSignUpView.swift` - Delete after extracting components

4. ✅ **Update Xcode project**
   - Remove file references if they show as red
   - Build and test

5. ✅ **Clean up AppState** (optional)
   - Remove `showGetStarted` property (no longer used)
   - Remove `shouldShowGetStarted` computed property (no longer used)
   - Remove `shouldShowAuth` computed property (no longer used)
   - Remove `markGetStartedAsSeen()` method (no longer used)

## Do You Want Me To:

1. **Extract the shared components now?**
   - I can create `AuthComponents.swift` with all reusable auth UI components
   - Update all imports automatically
   - Then you can safely delete the old files

2. **Just give you the plan?**
   - You can do the extraction and deletion manually
   - Use the commands above when ready

**My Recommendation**: Let me extract the shared components first (Option 1), then you can safely delete the old files immediately after testing.
