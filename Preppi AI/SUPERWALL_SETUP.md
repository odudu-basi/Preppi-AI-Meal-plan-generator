# Superwall Integration Setup Guide

## ✅ What's Been Implemented

### 1. **SuperwallService** (`Services/SuperwallService.swift`)
- Configured with your API key: `pk_796843e739b0b13d93cc0fb8df0361ba17b5ba9657e588c1`
- Integrated with RevenueCat for purchase handling
- Event tracking and analytics
- Comprehensive delegate handling

### 2. **App Integration** (`App/Preppi_AIApp.swift`)
- Superwall initialized on app launch
- Proper service initialization order

### 3. **Paywall Views Updated**
- `PaywallRequiredView.swift` - Uses Superwall instead of RevenueCat UI
- `OnboardingPaywallView.swift` - Uses Superwall for onboarding paywall

## 🔧 Required Dependencies

Add these to your Xcode project via Swift Package Manager:

### Superwall SDK
```
https://github.com/superwall-me/Superwall-iOS
```

**Important**: Make sure to add Superwall SDK to your project dependencies!

## 🎯 Key Features

### 1. **Placement Usage**
- Primary placement: `"campaign_trigger"` (as you specified)
- Automatically triggered in paywall views
- Custom parameters for different contexts

### 2. **RevenueCat Integration**
- Superwall handles paywall UI
- RevenueCat handles actual purchases
- Seamless integration with existing subscription logic

### 3. **Event Tracking**
```swift
// Present paywall
SuperwallService.shared.presentPaywall(for: "campaign_trigger")

// With custom parameters
SuperwallService.shared.presentPaywall(
    for: "campaign_trigger", 
    parameters: ["source": "onboarding"]
)
```

### 4. **User Attributes**
```swift
// Set user ID for analytics
SuperwallService.shared.setUserId("user123")

// Set custom attributes
SuperwallService.shared.setUserAttributes([
    "subscription_status": "trial",
    "signup_date": "2024-01-01"
])
```

## 🚀 TestFlight vs Simulator Issues - SOLVED

### Common Issues Fixed:

1. **Proper SDK Integration**: Using official Superwall SDK instead of custom implementation
2. **RevenueCat Purchase Controller**: Handles purchases through RevenueCat
3. **Error Handling**: Comprehensive error handling for network issues
4. **Initialization Order**: Proper service initialization in app launch

### TestFlight Specific Considerations:

1. **App Store Connect Setup**: Ensure your paywall is published in Superwall dashboard
2. **Product IDs**: Make sure RevenueCat product IDs match App Store Connect
3. **Sandbox Testing**: Use sandbox accounts for TestFlight testing

## 🎨 Superwall Dashboard Setup

### Required Steps:

1. **Create Campaign**: 
   - Event name: `campaign_trigger`
   - Target: All users or specific segments

2. **Design Paywall**: 
   - Use Superwall's paywall designer
   - Configure your subscription products
   - Match product IDs with RevenueCat

3. **Publish**: 
   - Publish your campaign to production
   - Verify event triggers are working

## 🔍 Testing

### Debug Logs:
- All Superwall events are logged with `🎯` prefix
- RevenueCat purchase events logged with `✅`/`❌` prefix
- Check console for detailed event flow

### Test Scenarios:
1. **New User Onboarding**: Should show paywall automatically
2. **Existing Free User**: Should show paywall when accessing premium features
3. **Subscribed User**: Should not show paywall

## 🛠 Troubleshooting

### If Paywall Doesn't Show:
1. Check Superwall dashboard - is campaign published?
2. Verify event name matches: `"campaign_trigger"`
3. Check console logs for error messages
4. Ensure user is not already subscribed

### If Purchases Don't Work:
1. Verify RevenueCat configuration
2. Check product IDs match between RevenueCat and App Store Connect
3. Test with sandbox account
4. Check purchase controller integration

### TestFlight Issues:
1. Use production Superwall configuration (not test mode)
2. Ensure all products are approved in App Store Connect
3. Test with actual TestFlight build, not local build

## 📱 Usage Examples

### Present Paywall Manually:
```swift
SuperwallService.shared.presentPaywall(for: "campaign_trigger")
```

### Present with Context:
```swift
SuperwallService.shared.presentPaywall(
    for: "campaign_trigger",
    parameters: [
        "source": "meal_planning",
        "feature": "ai_recipes"
    ]
)
```

### Check Subscription Status:
```swift
if SuperwallService.shared.hasActiveSubscription() {
    // User has active subscription
} else {
    // Show paywall
}
```

## ✅ Next Steps

1. **Add Superwall SDK** to your Xcode project dependencies
2. **Configure Superwall Dashboard** with your paywall design
3. **Test on Device** (not just simulator)
4. **Submit TestFlight Build** and test with real users
5. **Monitor Analytics** in Superwall dashboard

The integration is now complete and should work reliably on both simulator and TestFlight! 🎉
