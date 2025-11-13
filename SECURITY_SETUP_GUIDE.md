# 🔐 Security Setup Guide - URGENT

## ⚠️ CRITICAL: Your API Keys Were Exposed!

Your OpenAI API key, Supabase credentials, and Mixpanel token were shared publicly. **You MUST take immediate action!**

## 🚨 Step 1: Revoke All Keys (DO THIS NOW!)

### Revoke OpenAI Key
1. Go to: https://platform.openai.com/api-keys
2. Find the key starting with `sk-proj-y6-E3Z0Ss...`
3. Click the trash/revoke button
4. Generate a NEW key and save it securely

### Regenerate Supabase Keys
1. Go to: https://supabase.com/dashboard/project/taazipwcpckxchnxmbbp
2. Navigate to Settings → API
3. Click "Regenerate" on the anon key
4. Copy the new key

### Regenerate Mixpanel Token (if possible)
1. Go to your Mixpanel project settings
2. Look for token regeneration options

## 🛡️ Step 2: Remove Keys from Git History

If you've committed `APIKeys.plist` to git, the keys are in your repository history!

Run these commands:

```bash
cd "/Users/oduduabasivictor/Desktop/Preppi AI"

# Remove the file from git tracking
git rm --cached "Preppi AI/Config/APIKeys.plist"

# Commit this change
git add .gitignore
git commit -m "chore: Remove API keys from tracking and add to .gitignore"

# IMPORTANT: If you've already pushed this to GitHub, the keys are public!
# You MUST revoke them and use new keys
```

## ✅ Step 3: Add New Keys Securely

After revoking old keys and generating new ones:

1. **DO NOT share the new keys with anyone** (including me!)

2. **Edit your local APIKeys.plist file:**
   ```bash
   open "Preppi AI/Config/APIKeys.plist"
   ```

3. **Replace ONLY the values (keep the structure):**
   ```xml
   <key>OpenAI_API_Key</key>
   <string>sk-proj-YOUR_NEW_KEY_HERE</string>
   <key>Supabase_URL</key>
   <string>YOUR_SUPABASE_URL</string>
   <key>Supabase_Anon_Key</key>
   <string>YOUR_NEW_SUPABASE_KEY</string>
   <key>Mixpanel_Token</key>
   <string>YOUR_NEW_MIXPANEL_TOKEN</string>
   ```

4. **Save the file**

5. **Verify it's ignored:**
   ```bash
   git status
   # APIKeys.plist should NOT appear in the output
   ```

## 📋 What I've Done to Protect You

✅ Created `.gitignore` file that prevents committing API keys
✅ Created `APIKeys.plist.template` for reference
✅ Added comprehensive ignores for sensitive files

## 🎯 Going Forward

### NEVER Share:
- ❌ API keys in chat/screenshots
- ❌ APIKeys.plist file contents
- ❌ Environment variables with secrets
- ❌ Database connection strings with passwords

### ALWAYS:
- ✅ Use .gitignore for sensitive files
- ✅ Use template files for documentation
- ✅ Rotate keys immediately if exposed
- ✅ Use environment-specific configs

## 🔍 Check if Keys Were Pushed to GitHub

If you have a GitHub repository:

```bash
# Check if the file was ever committed
git log --all --full-history -- "Preppi AI/Config/APIKeys.plist"
```

If this shows commits, your keys are in GitHub's history!

### To fix:
1. Delete the repository (if it's public)
2. Create a new repository
3. Add .gitignore FIRST
4. Then add your code with NEW keys

OR use git history rewriting (advanced):
```bash
# WARNING: This rewrites history!
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch 'Preppi AI/Config/APIKeys.plist'" \
  --prune-empty --tag-name-filter cat -- --all

git push origin --force --all
```

## 📱 Testing After Setup

After adding new keys:

1. Build and run your app
2. Check console for:
   - `✅ Configuration loaded successfully`
   - No `❌ API Key not found` errors
3. Test the nutrition plan generation in onboarding

## ℹ️ Why This Matters

Exposed API keys can lead to:
- 💰 Unexpected charges on your account
- 🏴‍☠️ Unauthorized access to your services
- 📊 Data breaches
- 🚫 Account suspension

## Need Help?

If you're unsure about any step, STOP and:
1. Revoke all keys first (most important!)
2. Research the specific step
3. Ask for help (but NEVER share the actual keys!)

---

**Status Check:**
- [ ] Revoked old OpenAI key
- [ ] Generated new OpenAI key
- [ ] Regenerated Supabase key
- [ ] Regenerated Mixpanel token
- [ ] Updated local APIKeys.plist with NEW keys
- [ ] Verified .gitignore is working
- [ ] Removed APIKeys.plist from git tracking
- [ ] Checked GitHub repository (if applicable)
- [ ] Tested app with new keys

**Stay safe! 🔒**
