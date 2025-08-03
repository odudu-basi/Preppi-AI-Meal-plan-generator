# Preppi AI - Meal Plan Generator

An intelligent iOS meal planning app built with SwiftUI that generates personalized meal plans using OpenAI's GPT API and stores data with Supabase.

## Features

- 🤖 **AI-Powered Meal Planning**: Generate personalized meal plans using OpenAI GPT
- 🍽️ **Multiple Preparation Styles**: Choose between cooking fresh meals daily or batch cooking
- 🌍 **Cuisine Variety**: Select from various international cuisines
- 📱 **Native iOS App**: Built with SwiftUI for optimal performance
- 💾 **Cloud Storage**: Save and manage meal plans with Supabase
- 🛒 **Shopping Lists**: Auto-generate shopping lists from meal ingredients
- 👤 **User Profiles**: Personalized experience with dietary preferences
- 📋 **Meal Management**: View, save, and delete meal plans

## Setup Instructions

### 1. Configuration Setup

1. **Copy the configuration template:**
   ```bash
   cp Config/APIKeys.plist.template Config/APIKeys.plist
   ```

2. **Get your API credentials:**
   - **OpenAI API Key**: Get from [OpenAI Platform](https://platform.openai.com/api-keys)
   - **Supabase credentials**: Create a project at [supabase.com](https://supabase.com) and get your URL and anon key from the API settings

3. **Update the configuration file:**
   Open `Config/APIKeys.plist` and replace the placeholder values:
   ```xml
   <key>OpenAI_API_Key</key>
   <string>sk-your-actual-openai-key-here</string>
   <key>Supabase_URL</key>
   <string>https://your-project-id.supabase.co</string>
   <key>Supabase_Anon_Key</key>
   <string>your-supabase-anon-key-here</string>
   ```

### 2. Supabase Database Setup

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Run the SQL schema files in your Supabase SQL editor:
   - `supabase_schema.sql` (main schema)
   - `meal_plans_schema_only.sql` (meal plan tables)
   - `fix_meals_rls_policies.sql` (security policies)

### 3. Xcode Project Setup

1. Clone this repository
2. Open `Preppi AI.xcodeproj` in Xcode
3. Add the required Swift Package dependencies:
   - Supabase Swift SDK
   - Any other required packages
4. Build and run the project

## Project Structure

```
Preppi AI/
├── App/                          # App lifecycle and state management
├── Views/                        # SwiftUI views organized by feature
│   ├── Auth/                    # Authentication views
│   ├── Meal/                    # Meal planning and recipe views
│   ├── Onboarding/              # User onboarding flow
│   └── Profile/                 # User profile management
├── Services/                     # Business logic and API services
├── Models/                       # Data models and structures
├── Components/                   # Reusable UI components
└── Assets.xcassets/             # App icons and images
```

## Key Technologies

- **SwiftUI** - Modern iOS UI framework
- **OpenAI GPT API** - AI meal plan generation
- **Supabase** - Backend database and authentication
- **Swift Concurrency** - Async/await for network operations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Security Notes

- **Never commit API keys to version control** - The `Config/APIKeys.plist` file is gitignored to prevent accidental commits
- **Configuration file approach** - API keys are stored in a local plist file that is excluded from version control
- **Template provided** - Use `Config/APIKeys.plist.template` as a starting point for your configuration
- **Secure storage** - Consider using iOS Keychain for production apps storing sensitive data
- Follow iOS security best practices for sensitive data

## Important Files

- `Config/APIKeys.plist` - **DO NOT COMMIT** - Contains your actual API keys (gitignored)
- `Config/APIKeys.plist.template` - Template file showing the required configuration format
- `Services/ConfigurationService.swift` - Handles secure loading of API credentials

## License

This project is for educational and personal use.

---

Built with ❤️ using SwiftUI and AI