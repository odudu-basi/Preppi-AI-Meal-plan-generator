import Foundation

class ConfigurationService {
    static let shared = ConfigurationService()
    
    private var config: [String: Any] = [:]
    
    private init() {
        loadConfiguration()
    }
    
    private func loadConfiguration() {
        guard let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("❌ CRITICAL: APIKeys.plist file not found in bundle")
            print("📦 Bundle path: \(Bundle.main.bundlePath)")
            print("📂 Bundle contents: \(try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath))")
            config = [:]
            return
        }
        
        config = plist
        print("✅ Configuration loaded successfully")
    }
    
    var openAIAPIKey: String {
        guard let key = config["OpenAI_API_Key"] as? String, !key.isEmpty else {
            print("❌ OpenAI API Key not found in APIKeys.plist")
            return "" // Return empty string instead of crashing
        }
        return key
    }
    
    var supabaseURL: String {
        guard let url = config["Supabase_URL"] as? String, !url.isEmpty else {
            print("❌ Supabase URL not found in APIKeys.plist")
            return "" // Return empty string instead of crashing
        }
        return url
    }
    
    var supabaseAnonKey: String {
        guard let key = config["Supabase_Anon_Key"] as? String, !key.isEmpty else {
            print("❌ Supabase Anon Key not found in APIKeys.plist")
            return "" // Return empty string instead of crashing
        }
        return key
    }
    
    var mixpanelToken: String {
        guard let token = config["Mixpanel_Token"] as? String, !token.isEmpty else {
            print("❌ Mixpanel Token not found in APIKeys.plist")
            return "" // Return empty string instead of crashing
        }
        return token
    }
}