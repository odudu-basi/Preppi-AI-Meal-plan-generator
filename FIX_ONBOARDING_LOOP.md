# Fix: Onboarding Keeps Looping Back to Start

## 🐛 The Problem

When you click "Complete Onboarding", you're sent back to the beginning. Your debug log shows:

```
❌ Failed to update profile in Supabase:
   Could not find the 'country' column of 'user_profiles' in the schema cache
❌ Failed to save onboarding data to local storage
```

**Root Cause**: Your Supabase `user_profiles` table is **missing the `country` column**.

When onboarding tries to save your data, it fails because the database schema doesn't match the code. Since the save fails, `isOnboardingComplete` stays `false`, and you're sent back to onboarding.

---

## ✅ Solution: Add Missing Column to Supabase

### Step 1: Go to Supabase Dashboard

1. Open your browser
2. Go to: https://supabase.com/dashboard
3. Select your **Preppi AI** project
4. Navigate to: **SQL Editor** (in left sidebar)

### Step 2: Verify the Issue (Optional)

Run this query to see current columns:

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'user_profiles'
ORDER BY ordinal_position;
```

**Look for**: `country` column in the results
- ❌ If missing → Continue to Step 3
- ✅ If present → The issue is something else (see troubleshooting below)

### Step 3: Run the Migration

Create a **New Query** and paste this:

```sql
-- Add the missing 'country' column
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS country TEXT;
```

Click **"Run"** or press `Cmd/Ctrl + Enter`

**Expected Result:**
```
Success. No rows returned
```

### Step 4: Verify Fix

Run this to confirm the column was added:

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'user_profiles' AND column_name = 'country';
```

**Expected Result:**
```
column_name | data_type
------------|----------
country     | text
```

✅ Column added successfully!

### Step 5: Test in Your App

1. **Force close** your app completely
2. **Reopen** the app
3. **Complete onboarding again**
4. This time it should save successfully!

**Expected debug log:**
```
✅ User profile successfully saved to Supabase (upsert operation)
✅ Local backup saved
```

---

## 🔍 Additional Verification (Recommended)

Since `country` was missing, other columns might be too. Run this complete verification:

### Check All Required Columns

I've created `DATABASE_VERIFICATION.sql` with a full column checklist.

**Required columns:**
- ✅ user_id
- ✅ email
- ✅ name
- ✅ sex
- ❌ **country** ← Missing (causing error)
- ✅ age
- ✅ weight
- ✅ height
- ✅ likes_to_cook
- ✅ cooking_preference
- ✅ activity_level
- ✅ target_weight
- ✅ weight_loss_speed
- ✅ marketing_source
- ✅ motivations
- ✅ motivation_other
- ✅ challenges
- ✅ health_goals
- ✅ dietary_restrictions
- ✅ food_allergies
- ✅ weekly_budget
- ✅ onboarding_completed
- ✅ created_at
- ✅ updated_at

If ANY others are missing, add them with:

```sql
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS column_name data_type;
```

---

## 📋 Files Created for You

I've created these helper files:

### 1. `DATABASE_MIGRATION_ADD_COUNTRY.sql`
- Ready-to-run SQL migration
- Adds the `country` column
- Includes rollback instructions
- Just copy and paste into Supabase SQL Editor

### 2. `DATABASE_VERIFICATION.sql`
- Checks all columns in user_profiles
- Lists all required columns
- Helps identify any other missing columns

### 3. `FIX_ONBOARDING_LOOP.md` (this file)
- Complete troubleshooting guide
- Step-by-step instructions
- Testing procedures

---

## 🎯 Quick Fix (TL;DR)

```sql
-- In Supabase SQL Editor, run this:
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS country TEXT;
```

Then restart your app and try onboarding again.

---

## 🧪 Testing After Fix

After adding the column:

1. **Delete app from device** (fresh start)
2. **Rebuild and run**
3. **Complete onboarding flow**
4. **Check debug log** for:
   ```
   ✅ User profile successfully saved to Supabase
   💰 Onboarding completed - showing RevenueCat paywall
   ```
5. **You should see the paywall** (not loop back to onboarding)

---

## 🚨 Troubleshooting

### Issue: Column exists but still getting error

**Possible causes:**
1. **Schema cache issue** - Restart your app completely
2. **Different database** - Check you're in the correct Supabase project
3. **RLS policy blocking** - Check Row Level Security policies

**Fix:**
```sql
-- Refresh schema cache in Supabase
NOTIFY pgrst, 'reload schema';
```

### Issue: Migration fails with permission error

**Error:**
```
permission denied for table user_profiles
```

**Fix:**
- Make sure you're running the SQL as the project owner
- Check you're in the SQL Editor, not the Table Editor

### Issue: Still looping after adding column

**Check:**
1. Did you restart the app?
2. Is the column spelled correctly (`country` not `Country`)?
3. Run the verification query to confirm it exists

**Debug:**
Check if there are other missing columns by comparing the verification results with the required columns list above.

---

## 🔐 Why This Happened

When you added the new onboarding screens (like `CountryInputView`), the code started saving `country` data. But your Supabase table was created earlier and doesn't have this column.

**Timeline:**
1. Initially created `user_profiles` table (older schema)
2. Added new onboarding screens (like country selection)
3. Code now expects `country` column
4. Database doesn't have it → Save fails → Loop!

---

## 🎉 Success Indicators

After the fix, you'll see:

**In Debug Log:**
```
💾 Saving user profile to Supabase...
✅ User profile successfully saved to Supabase (upsert operation)
✅ Local backup saved
💰 Onboarding completed - showing RevenueCat paywall
```

**In App:**
- Complete onboarding
- See paywall screen (not back to onboarding start)
- Can proceed with subscription

---

## 📝 Prevention for Future

When adding new onboarding fields:

1. **Update Swift models** (UserOnboardingData, UserProfileUpdate)
2. **Update Supabase schema** (add column to user_profiles)
3. **Test on fresh device/account**

This ensures database and code stay in sync!

---

## Need Help?

If the migration doesn't work:

1. Check Supabase logs: Dashboard → Logs
2. Verify you're in the correct project
3. Check RLS policies aren't blocking inserts
4. Share the exact error message for more specific help
