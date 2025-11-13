import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers
import UserNotifications

class ShareViewController: SLComposeServiceViewController {
    private var isProcessing = false
    
    override func isContentValid() -> Bool {
        // Check if we have valid image content
        return hasImageAttachment()
    }
    
    override func didSelectPost() {
        // Prevent multiple processing calls
        guard !isProcessing else { return }
        isProcessing = true
        
        print("📸 ShareExtension: Starting silent image processing...")
        
        // Process the image silently in background
        handleSharedContent { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    // Successfully processed the content, open the main app
                    self?.openMainApp()
                } else {
                    // Close silently on error
                    self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the compose view immediately
        self.view.isHidden = true
        
        // Automatically process the shared image without showing UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.didSelectPost()
        }
    }
    
    override func presentationAnimationDidFinish() {
        super.presentationAnimationDidFinish()
        
        // Also trigger processing when animation finishes (backup)
        self.didSelectPost()
    }
    
    override func configurationItems() -> [Any]! {
        // Return an array of SLComposeSheetConfigurationItem to customize the compose sheet
        return []
    }
    
    private func hasImageAttachment() -> Bool {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            return false
        }
        
        for inputItem in inputItems {
            guard let attachments = inputItem.attachments else { continue }
            
            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    return true
                }
            }
        }
        
        return false
    }
    
    
    private func handleSharedContent(completion: @escaping (Bool) -> Void) {
        // Only handle images
        if hasImageAttachment() {
            handleSharedImage(completion: completion)
            return
        }
        
        print("❌ ShareExtension: No supported content found")
        completion(false)
    }
    
    private func handleSharedImage(completion: @escaping (Bool) -> Void) {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            completion(false)
            return
        }
        
        var imageFound = false
        let group = DispatchGroup()
        
        for inputItem in inputItems {
            guard let attachments = inputItem.attachments else { continue }
            
            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    imageFound = true
                    group.enter()
                    
                    attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (data, error) in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("❌ Error loading image: \(error)")
                            return
                        }
                        
                        var image: UIImage?
                        
                        if let imageData = data as? Data {
                            image = UIImage(data: imageData)
                        } else if let imageURL = data as? URL {
                            if let imageData = try? Data(contentsOf: imageURL) {
                                image = UIImage(data: imageData)
                            }
                        } else if let uiImage = data as? UIImage {
                            image = uiImage
                        }
                        
                        if let image = image {
                            self?.saveImageToSharedContainer(image)
                        }
                    }
                }
            }
        }
        
        if !imageFound {
            completion(false)
            return
        }
        
        group.notify(queue: .main) {
            completion(true)
        }
    }
    
    private func saveImageToSharedContainer(_ image: UIImage) {
        print("📸 ShareExtension: Attempting to save image (size: \(image.size))")
        
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.-5.Preppi-AI.shared"
        ) else {
            print("❌ ShareExtension: Failed to access shared container - check App Groups configuration")
            return
        }
        
        print("✅ ShareExtension: Shared container URL: \(containerURL.path)")
        
        let sharedImageURL = containerURL.appendingPathComponent("shared_image.jpg")
        print("📁 ShareExtension: Saving image to: \(sharedImageURL.path)")
        
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ ShareExtension: Failed to convert image to JPEG data")
            return
        }
        
        print("📊 ShareExtension: Image data size: \(imageData.count) bytes")
        
        do {
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: sharedImageURL.path) {
                try FileManager.default.removeItem(at: sharedImageURL)
                print("🗑️ ShareExtension: Removed existing shared image")
            }
            
            // Write new image data
            try imageData.write(to: sharedImageURL)
            print("✅ ShareExtension: Successfully saved shared image to container")
            
            // Verify the file was written
            if FileManager.default.fileExists(atPath: sharedImageURL.path) {
                print("✅ ShareExtension: Verified file exists at shared location")
            } else {
                print("❌ ShareExtension: File verification failed - file not found after writing")
            }
        } catch {
            print("❌ ShareExtension: Failed to save image to shared container: \(error)")
        }
    }
    
    
    private func openMainApp() {
        print("🚀 ShareExtension: Attempting to open main app")
        
        // Create a notification in the shared container to tell the main app about the shared image
        saveSharedImageNotification()
        
        // Open the main app with a custom URL scheme
        let urlString = "preppi-ai://shared-image"
        
        if let url = URL(string: urlString) {
            // Try multiple methods to open the app
            if #available(iOS 14.0, *) {
                extensionContext?.open(url, completionHandler: { success in
                    print("🚀 ShareExtension: URL open result: \(success)")
                    if !success {
                        // If URL opening failed, show instructions to user
                        DispatchQueue.main.async {
                            self.showOpenAppInstructions()
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                        }
                    }
                })
            } else {
                // Fallback for older iOS versions
                var responder: UIResponder? = self as UIResponder
                let selector = #selector(openURL(_:))
                
                var urlOpened = false
                while responder != nil {
                    if responder!.responds(to: selector) && responder != self {
                        responder!.perform(selector, with: url)
                        urlOpened = true
                        break
                    }
                    responder = responder?.next
                }
                
                if !urlOpened {
                    showOpenAppInstructions()
                } else {
                    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                }
            }
        } else {
            print("❌ ShareExtension: Failed to create URL")
            showOpenAppInstructions()
        }
    }
    
    private func saveSharedImageNotification() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.-5.Preppi-AI.shared"
        ) else {
            return
        }
        
        let notificationURL = containerURL.appendingPathComponent("shared_image_notification.txt")
        let timestamp = Date().timeIntervalSince1970
        
        do {
            try "\(timestamp)".write(to: notificationURL, atomically: true, encoding: .utf8)
            print("✅ ShareExtension: Saved notification file")
            
            // Schedule local notification
            scheduleLocalNotification()
        } catch {
            print("❌ ShareExtension: Failed to save notification: \(error)")
        }
    }
    
    private func scheduleLocalNotification() {
        print("📱 ShareExtension: Scheduling local notification")
        
        let content = UNMutableNotificationContent()
        content.title = "Preppi AI"
        content.body = "Your image is ready! Click here to open and get your recipe."
        content.sound = .default
        content.categoryIdentifier = "SHARED_IMAGE"
        
        // Add custom data to identify this as a shared image notification
        content.userInfo = ["action": "shared_image"]
        
        // Schedule notification to appear in 1 second
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "shared_image_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ ShareExtension: Failed to schedule notification: \(error)")
            } else {
                print("✅ ShareExtension: Notification scheduled successfully")
            }
        }
    }
    
    private func showOpenAppInstructions() {
        let alert = UIAlertController(
            title: "Image Saved!",
            message: "Your image has been saved. Please open Preppi AI to continue with recipe analysis.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        })
        
        present(alert, animated: true)
    }
    
    private func showErrorAndClose() {
        // Close silently without showing error UI
        print("❌ ShareExtension: Failed to process image, closing silently")
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    @objc private func openURL(_ url: URL) {
        // This method will be called by perform(selector:with:)
        // The actual opening is handled by the system
    }
}
