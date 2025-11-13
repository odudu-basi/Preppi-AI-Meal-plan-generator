# Share Extension Setup Guide

## Overview
This guide explains how to set up the iOS Share Extension that allows users to share images directly from other apps (Photos, Safari, etc.) to Preppi AI for recipe analysis.

## ✅ Completed Code Implementation

### 1. Main App Updates
- ✅ **AppState.swift**: Added shared image handling properties and methods
- ✅ **Preppi_AIApp.swift**: Added URL scheme handling for shared images
- ✅ **ContentView.swift**: Added notification listener for shared images
- ✅ **CameraView.swift**: Added automatic navigation to PhotoProcessingView for shared images
- ✅ **Info.plist**: Added URL scheme configuration (`preppi-ai://`)

### 2. Share Extension Files Created
- ✅ **ShareViewController.swift**: Main share extension logic
- ✅ **Info.plist**: Share extension configuration
- ✅ **MainInterface.storyboard**: Share extension UI

## 🔧 Required Manual Steps in Xcode

### Step 1: Add Share Extension Target

1. **Open Xcode project**
2. **Add new target**:
   - File → New → Target
   - Choose "Share Extension" under iOS
   - Product Name: `Preppi AI Share Extension`
   - Bundle Identifier: `com.preppi.ai.share-extension`
   - Language: Swift

3. **Configure target settings**:
   - Deployment Target: iOS 15.0 (or your minimum version)
   - Team: Your development team
   - Bundle Identifier: `com.preppi.ai.share-extension`

### Step 2: Add App Groups Capability

Both the main app and share extension need to share data through App Groups.

1. **Main App Target**:
   - Select your main app target
   - Go to "Signing & Capabilities"
   - Click "+" and add "App Groups"
   - Add group: `group.com.preppi.ai.shared`

2. **Share Extension Target**:
   - Select the share extension target
   - Go to "Signing & Capabilities"
   - Click "+" and add "App Groups"
   - Add the same group: `group.com.preppi.ai.shared`

### Step 3: Replace Generated Files

1. **Replace ShareViewController.swift**:
   - Delete the generated `ShareViewController.swift`
   - Add the `ShareViewController.swift` file from this project

2. **Replace Info.plist**:
   - Replace the share extension's `Info.plist` with the one from this project

3. **Replace MainInterface.storyboard**:
   - Replace the generated storyboard with the one from this project

### Step 4: Add Required Frameworks

Add these frameworks to the Share Extension target:
- `Social.framework`
- `MobileCoreServices.framework`
- `UniformTypeIdentifiers.framework` (iOS 14+)

## 🎯 How It Works

### User Flow
1. **User finds an image** in Photos, Safari, or any other app
2. **Taps the share button** (square with arrow up)
3. **Selects "Preppi AI"** from the share sheet
4. **Share extension opens** with a custom UI
5. **User taps "Post"** to share the image
6. **Extension processes image** and saves to shared container
7. **Main app opens** automatically via URL scheme
8. **PhotoProcessingView appears** with the shared image loaded

### Technical Flow
1. **Share Extension receives image** from system
2. **Image is processed** and saved to App Groups container
3. **URL scheme triggered**: `preppi-ai://shared-image`
4. **Main app receives URL** in `onOpenURL`
5. **Notification sent** to ContentView
6. **AppState updated** with shared image
7. **CameraView detects change** and shows PhotoProcessingView

## 📱 Testing

### Simulator Testing
1. **Build and run** both targets (main app + extension)
2. **Open Photos app** in simulator
3. **Select any image**
4. **Tap share button**
5. **Look for "Preppi AI"** in share sheet
6. **Test the complete flow**

### Device Testing
1. **Install via Xcode** or TestFlight
2. **Test with real photos** from Camera Roll
3. **Test sharing from Safari** (save image first)
4. **Verify smooth app transition**

## 🐛 Troubleshooting

### Common Issues

1. **Share Extension not appearing**
   - Check bundle identifier configuration
   - Verify App Groups are correctly set up
   - Ensure extension is properly embedded in main app

2. **App doesn't open after sharing**
   - Verify URL scheme in main app's Info.plist
   - Check `CFBundleURLSchemes` contains `preppi-ai`
   - Ensure `onOpenURL` handler is properly set up

3. **Image not loading in main app**
   - Verify App Groups container access
   - Check file permissions in shared container
   - Ensure image is properly saved as JPEG data

4. **Extension crashes on image processing**
   - Check image format compatibility
   - Verify memory usage (extensions have limited memory)
   - Add error handling for unsupported formats

### Debug Logging

The implementation includes comprehensive logging:
- `📸` - Share extension image processing
- `📱` - Main app URL handling
- `✅` - Success operations
- `❌` - Error conditions

Check Xcode console for these logs during testing.

## 🚨 Important Notes

### App Store Requirements
- **Privacy**: Update privacy policy to mention image sharing
- **Permissions**: No additional permissions needed for sharing
- **Review**: Share extensions are reviewed as part of main app

### Performance Considerations
- **Memory**: Share extensions have limited memory (~16MB)
- **Processing**: Keep image processing minimal in extension
- **Storage**: Clean up shared container files after processing

### Security
- **Sandboxing**: Extension runs in separate sandbox
- **Data**: Only shared through App Groups container
- **Privacy**: Images are processed locally, not uploaded

## 📋 Final Checklist

Before submitting to App Store:
- [ ] Share extension target added to Xcode project
- [ ] App Groups configured for both targets
- [ ] URL scheme properly configured
- [ ] Extension appears in share sheet
- [ ] Complete flow works end-to-end
- [ ] Tested on both simulator and device
- [ ] Error handling works properly
- [ ] Memory usage is optimized

## 🎉 Success!

Once set up correctly, users will be able to:
- Share any image from any app to Preppi AI
- Get instant recipe analysis without manual photo selection
- Seamlessly transition from sharing to recipe processing
- Enjoy a smooth, integrated iOS experience

This feature significantly improves user experience by reducing friction in the recipe analysis workflow!
