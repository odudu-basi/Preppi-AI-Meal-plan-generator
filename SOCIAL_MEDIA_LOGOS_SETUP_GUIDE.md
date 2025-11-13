# Social Media Logos Setup Guide

## Overview
This guide explains how to add official brand logos for social media platforms in the "How did you hear about us?" onboarding page.

## What's Been Done
1. ✅ Made the MarketingSourceView scrollable
2. ✅ Updated code to support custom brand logo images
3. ✅ Created imageset folders in Assets.xcassets for all social platforms
4. ✅ Added Contents.json configuration files

## What You Need to Do
Add the actual logo image files to the imagesets. The code will automatically use them once they're in place.

## Image Requirements

### File Specifications
- **Format**: PNG with transparent background
- **Size**: Recommended 120x120px or 150x150px (square)
- **Color**: Full color logos (the app will handle any color adjustments)
- **Background**: Transparent

### Logo Files Needed
You need to add one PNG file to each of these folders:

1. **App Store Logo**
   - Folder: `Assets.xcassets/logo-appstore.imageset/`
   - Filename: `logo-appstore.png`
   - Download from: [Apple Marketing Resources](https://www.apple.com/app-store/marketing-guidelines/)

2. **Instagram Logo**
   - Folder: `Assets.xcassets/logo-instagram.imageset/`
   - Filename: `logo-instagram.png`
   - Download from: [Instagram Brand Resources](https://about.instagram.com/brand/gradient)
   - Use the full-color Instagram camera icon

3. **TikTok Logo**
   - Folder: `Assets.xcassets/logo-tiktok.imageset/`
   - Filename: `logo-tiktok.png`
   - Download from: [TikTok Brand Assets](https://newsroom.tiktok.com/en-us/brand-guidelines)
   - Use the musical note icon

4. **Facebook Logo**
   - Folder: `Assets.xcassets/logo-facebook.imageset/`
   - Filename: `logo-facebook.png`
   - Download from: [Facebook Brand Resources](https://about.meta.com/brand/resources/facebook/)
   - Use the "f" logo in white or the full color version

5. **Google Logo**
   - Folder: `Assets.xcassets/logo-google.imageset/`
   - Filename: `logo-google.png`
   - Download from: [Google Brand Resource Center](https://about.google/brand-resource-center/)
   - Use the Google "G" logo

6. **YouTube Logo**
   - Folder: `Assets.xcassets/logo-youtube.imageset/`
   - Filename: `logo-youtube.png`
   - Download from: [YouTube Brand Resources](https://www.youtube.com/howyoutubeworks/resources/brand-resources/)
   - Use the YouTube play button icon

## Alternative: Free Icon Resources

If you can't access official brand resources, you can use these free alternatives:

### Option 1: Icons8
- Visit: https://icons8.com/icons/set/social-media
- Search for each platform
- Download PNG at 100-150px
- Ensure transparent background

### Option 2: Simple Icons
- Visit: https://simpleicons.org/
- Search for each brand
- Download SVG (you'll need to convert to PNG)
- Use an online converter like CloudConvert

### Option 3: Flaticon
- Visit: https://www.flaticon.com/free-icons/social-media
- Search for official-style social media logos
- Download PNG format
- Check license requirements (attribution may be needed)

## How to Add Images

### Using Xcode (Recommended)
1. Open your project in Xcode
2. In the Project Navigator, expand `Assets.xcassets`
3. You'll see the new logo imagesets (logo-appstore, logo-instagram, etc.)
4. Drag and drop each PNG file into its corresponding imageset
5. Make sure the file lands in the "1x" slot

### Using Finder
1. Download/prepare all 6 logo PNG files
2. Rename them exactly as specified above
3. Copy each file into its respective folder:
   ```
   Preppi AI/Assets.xcassets/logo-appstore.imageset/logo-appstore.png
   Preppi AI/Assets.xcassets/logo-instagram.imageset/logo-instagram.png
   Preppi AI/Assets.xcassets/logo-tiktok.imageset/logo-tiktok.png
   Preppi AI/Assets.xcassets/logo-facebook.imageset/logo-facebook.png
   Preppi AI/Assets.xcassets/logo-google.imageset/logo-google.png
   Preppi AI/Assets.xcassets/logo-youtube.imageset/logo-youtube.png
   ```

## Testing
1. Build and run the app
2. Go to the "How did you hear about us?" page in onboarding
3. You should see the brand logos instead of SF Symbols
4. The "Friend or family" option will still use an SF Symbol (this is intentional)

## Fallback Behavior
If a logo image is not found, the app will automatically fall back to using SF Symbols icons, so the app won't break if images are missing.

## Brand Compliance Notes

### Important
When using official brand logos, you must comply with each platform's brand guidelines:

- **App Store**: Follow Apple's guidelines for App Store badge usage
- **Instagram**: Use only approved Instagram assets
- **TikTok**: Follow TikTok's brand guidelines
- **Facebook**: Use official Facebook brand assets
- **Google**: Follow Google's brand identity guidelines
- **YouTube**: Follow YouTube's branding guidelines

### General Rules
1. Don't modify the logos (no rotation, distortion, or color changes)
2. Don't use outdated logos
3. Maintain proper spacing around logos
4. Use official assets when possible

## Current File Paths

All imageset folders are located at:
```
/Users/oduduabasivictor/Desktop/Preppi AI/Preppi AI/Assets.xcassets/
```

## Quick Command to Check Status
Run this in Terminal to see which logos are already added:
```bash
ls -la "/Users/oduduabasivictor/Desktop/Preppi AI/Preppi AI/Assets.xcassets/"logo-*.imageset/*.png
```

## Support
If you have questions or need help:
1. Check that filenames match exactly (case-sensitive)
2. Verify PNG files have transparent backgrounds
3. Ensure images are square (equal width and height)
4. Try rebuilding the project in Xcode after adding images

---

**Status**: Image placeholders created ✅ | Logo files needed ⏳
