import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("🔄 ImagePicker: Image selected, processing...")
            
            let selectedImage: UIImage?
            
            if let editedImage = info[.editedImage] as? UIImage {
                print("✅ ImagePicker: Using edited image")
                selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                print("✅ ImagePicker: Using original image")
                selectedImage = originalImage
            } else {
                print("❌ ImagePicker: No image found in picker info")
                selectedImage = nil
            }
            
            // Call the callback immediately, don't wait for dismissal
            if let image = selectedImage {
                print("📸 ImagePicker: Calling onImagePicked with image size: \(image.size)")
                DispatchQueue.main.async {
                    self.parent.onImagePicked(image)
                }
            } else {
                print("❌ ImagePicker: No image to pass to parent")
            }
            
            // The parent will handle dismissing the picker
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
