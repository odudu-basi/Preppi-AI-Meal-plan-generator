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
    
    private init() {
        guard let url = URL(string: ConfigurationService.shared.supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: ConfigurationService.shared.supabaseAnonKey
        )
    }
}
