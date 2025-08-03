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
            fatalError("APIKeys.plist file not found. Please ensure APIKeys.plist is added to your project.")
        }
        
        config = plist
    }
    
    var openAIAPIKey: String {
        guard let key = config["OpenAI_API_Key"] as? String, !key.isEmpty else {
            fatalError("OpenAI API Key not found in APIKeys.plist")
        }
        return key
    }
    
    var supabaseURL: String {
        guard let url = config["Supabase_URL"] as? String, !url.isEmpty else {
            fatalError("Supabase URL not found in APIKeys.plist")
        }
        return url
    }
    
    var supabaseAnonKey: String {
        guard let key = config["Supabase_Anon_Key"] as? String, !key.isEmpty else {
            fatalError("Supabase Anon Key not found in APIKeys.plist")
        }
        return key
    }
}