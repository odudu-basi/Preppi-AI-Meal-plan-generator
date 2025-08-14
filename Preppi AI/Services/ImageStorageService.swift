import Foundation
import Supabase

/// Service for downloading and storing images permanently in Supabase Storage
class ImageStorageService {
    static let shared = ImageStorageService()
    
    private let supabase = SupabaseService.shared
    private let bucketName = "meal-images"
    
    private init() {}
    
    /// Downloads an image from a temporary URL and stores it permanently in Supabase Storage
    /// - Parameters:
    ///   - temporaryUrl: The temporary DALL-E image URL
    ///   - mealId: The meal ID to use in the filename
    /// - Returns: Permanent Supabase Storage URL
    func downloadAndStoreImage(from temporaryUrl: String, for mealId: UUID) async throws -> String {
        print("📥 Starting image download and storage for meal ID: \(mealId)")
        
        // Step 0: Ensure bucket exists first
        do {
            try await ensureBucketExists()
            print("✅ Bucket verified/created successfully")
        } catch {
            print("❌ Bucket creation/verification failed: \(error)")
            print("⚠️ You may need to create the 'meal-images' bucket manually in Supabase Dashboard")
            // Continue anyway in case bucket already exists
        }
        
        // Step 1: Download the image from the temporary URL
        guard let url = URL(string: temporaryUrl) else {
            throw ImageStorageError.invalidURL
        }
        
        let (imageData, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ImageStorageError.downloadFailed
        }
        
        print("✅ Image downloaded successfully - Size: \(imageData.count) bytes")
        
        // Step 2: Generate a unique filename
        let fileName = generateFileName(for: mealId)
        
        // Step 3: Upload to Supabase Storage
        do {
            let _ = try await supabase.storage
                .from(bucketName)
                .upload(
                    path: fileName,
                    file: imageData
                )
            
            print("✅ Image uploaded to Supabase Storage: \(fileName)")
        } catch {
            print("❌ Upload failed: \(error)")
            print("❌ Upload error details: \(error.localizedDescription)")
            if error.localizedDescription.contains("Bucket not found") {
                print("💡 SOLUTION: Create 'meal-images' bucket manually in your Supabase Dashboard")
                print("💡 Make sure to set it as PUBLIC and add proper storage policies")
                throw ImageStorageError.bucketNotFound
            } else {
                throw ImageStorageError.uploadFailed
            }
        }
        
        // Step 4: Get the public URL
        do {
            let publicURL = try supabase.storage
                .from(bucketName)
                .getPublicURL(path: fileName)
            
            print("✅ Generated permanent URL: \(publicURL)")
            return publicURL.absoluteString
            
        } catch {
            print("❌ Failed to get public URL: \(error)")
            print("❌ Public URL error details: \(error.localizedDescription)")
            throw ImageStorageError.uploadFailed
        }
    }
    
    /// Deletes an image from Supabase Storage
    /// - Parameter mealId: The meal ID to delete the image for
    func deleteImage(for mealId: UUID) async throws {
        let fileName = generateFileName(for: mealId)
        
        try await supabase.storage
            .from(bucketName)
            .remove(paths: [fileName])
        
        print("🗑️ Image deleted from storage: \(fileName)")
    }
    
    /// Creates the storage bucket if it doesn't exist
    func ensureBucketExists() async throws {
        do {
            // Try to create the bucket (will fail if it already exists, which is fine)
            let _ = try await supabase.storage.createBucket(bucketName)
            print("✅ Created new storage bucket: \(bucketName)")
        } catch {
            // Bucket likely already exists, which is fine
            print("ℹ️ Storage bucket \(bucketName) already exists or creation failed: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func generateFileName(for mealId: UUID) -> String {
        let timestamp = Date().timeIntervalSince1970
        return "meal_\(mealId.uuidString)_\(Int(timestamp)).png"
    }
}

// MARK: - Error Types

enum ImageStorageError: Error, LocalizedError {
    case invalidURL
    case downloadFailed
    case uploadFailed
    case bucketNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid image URL provided"
        case .downloadFailed:
            return "Failed to download image from temporary URL"
        case .uploadFailed:
            return "Failed to upload image to storage"
        case .bucketNotFound:
            return "Storage bucket not found"
        }
    }
}