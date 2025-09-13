import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    // Explicitly expose the auth client
    var auth: AuthClient {
        client.auth
    }
    
    // Optionally expose other services too
    var database: PostgrestClient {
        client.database
    }
    
    var realtime: RealtimeClient {
        client.realtime
    }
    
    var storage: SupabaseStorageClient {
        client.storage
    }
    
    private init() {
        let supabaseURLString = ConfigurationService.shared.supabaseURL
        guard !supabaseURLString.isEmpty, let url = URL(string: supabaseURLString) else {
            print("❌ Invalid or missing Supabase URL: '\(supabaseURLString)'")
            // Create a dummy client with fallback URL to prevent crash
            let fallbackURL = URL(string: "https://example.supabase.co")!
            self.client = SupabaseClient(
                supabaseURL: fallbackURL,
                supabaseKey: "dummy-key"
            )
            return
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: ConfigurationService.shared.supabaseAnonKey
        )
    }
}
