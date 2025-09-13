# Superwall Integration Guide

## Overview
This guide explains how to integrate Superwall for paywall UI with RevenueCat handling the actual purchases in your iOS app.

## ✅ Completed Setup

### 1. Code Integration
- ✅ `SuperwallService.swift` - Handles Superwall configuration and event tracking
- ✅ `PaywallRequiredView.swift` - Updated to use Superwall for paywall presentation
- ✅ `OnboardingPaywallView.swift` - Updated to use Superwall for onboarding paywall
- ✅ `Preppi_AIApp.swift` - Initializes Superwall on app launch

### 2. API Configuration
- **API Key**: `pk_796843e739b0b13d93cc0fb8df0361ba17b5ba9657e588c1`
- **Placement**: `campaign_trigger`

## 🔧 Required Manual Steps

### Step 1: Add Superwall SDK to Xcode Project

1. Open your Xcode project
2. Go to **File > Add Package Dependencies**
3. Enter the Superwall SDK URL: `https://github.com/superwall-me/Superwall-iOS`
4. Click **Add Package**
5. Select your app target and click **Add Package**

### Step 2: Configure Superwall Dashboard

1. Go to [Superwall Dashboard](https://superwall.com/dashboard)
2. Log in to your account
3. Create a new campaign with the identifier: `campaign_trigger`
4. Set up your paywall design and rules
5. Configure the paywall to trigger on the `campaign_trigger` event

### Step 3: Configure RevenueCat Integration

Since we're using a simplified integration, purchases will be handled by your existing RevenueCat setup. The flow works as follows:

1. **Superwall presents the paywall UI**
2. **User taps purchase button**
3. **RevenueCat handles the actual purchase**
4. **App checks RevenueCat entitlements to determine access**

## 🎯 How It Works

### Paywall Presentation Flow

1. **App calls**: `SuperwallService.shared.presentPaywall(for: "campaign_trigger")`
2. **Superwall checks**: Campaign rules and user eligibility
3. **If eligible**: Paywall is presented to user
4. **User interaction**: User can purchase or dismiss
5. **Purchase handling**: Done through your existing RevenueCat integration
6. **Access check**: App checks `RevenueCatService.shared.isProUser`

### Event Tracking

The service automatically tracks various Superwall events:
- Paywall opens/closes
- Transaction events
- User interactions
- Campaign performance

## 📱 Usage Examples

### Present Paywall (Basic)
```swift
SuperwallService.shared.presentPaywall()
```

### Present Paywall with Parameters
```swift
SuperwallService.shared.presentPaywall(
    for: "campaign_trigger",
    parameters: [
        "source": "onboarding",
        "user_type": "new"
    ]
)
```

### Check Subscription Status
```swift
let hasSubscription = SuperwallService.shared.hasActiveSubscription()
```

### Set User Attributes
```swift
SuperwallService.shared.setUserAttributes([
    "user_id": "12345",
    "subscription_status": "active",
    "signup_date": "2024-01-15"
])
```

## 🔍 Testing

### Simulator Testing
1. Run app in iOS Simulator
2. Trigger paywall presentation
3. Verify paywall appears correctly
4. Test purchase flow (will use sandbox)

### TestFlight Testing
1. Build and upload to TestFlight
2. Install on physical device
3. Test complete purchase flow
4. Verify subscription status updates correctly

## 🐛 Troubleshooting

### Common Issues

1. **Paywall doesn't appear**
   - Check campaign configuration in Superwall dashboard
   - Verify `campaign_trigger` event is set up correctly
   - Check console logs for Superwall events

2. **Purchases not working**
   - Verify RevenueCat is properly configured
   - Check App Store Connect sandbox settings
   - Ensure products are available in RevenueCat dashboard

3. **TestFlight issues**
   - Make sure Superwall campaign is published (not draft)
   - Verify production API key is being used
   - Check that RevenueCat is configured for production

### Debug Logging

The service includes comprehensive logging. Check Xcode console for:
- `🎯 Superwall:` - Event tracking and delegate callbacks
- `✅ Superwall configured` - Successful initialization
- `❌` - Error messages

## 📋 Next Steps

1. **Add Superwall SDK** to Xcode project (Step 1 above)
2. **Configure dashboard** with `campaign_trigger` placement (Step 2 above)
3. **Test on simulator** to verify basic functionality
4. **Test on TestFlight** to ensure production readiness
5. **Monitor analytics** in both Superwall and RevenueCat dashboards

## 🚨 Important Notes

- **Simplified Integration**: We're using basic Superwall configuration without custom purchase controller
- **RevenueCat Handles Purchases**: All purchase logic remains in your existing RevenueCat setup
- **Subscription Status**: App checks RevenueCat for subscription status, not Superwall
- **Analytics**: Both Superwall and RevenueCat will track events independently

This approach ensures maximum compatibility and reduces integration complexity while still providing Superwall's powerful paywall UI capabilities.
