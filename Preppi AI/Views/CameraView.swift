import SwiftUI
import PhotosUI

struct CameraView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingActionSheet = false
    @State private var showingImagePicker = false
    @State private var showingPhotoProcessing = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var showingCookbooks = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient matching app theme
                LinearGradient(
                    colors: [
                        Color("AppBackground"),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 20) {
                        // Main headline
                        Text("Snap a picture, get the recipe")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 20)
                        
                        // Hero image
                        Image("food_background")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 340, height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                    }
                    .padding(.top, 5)
                    
                    // Main Action Buttons
                    VStack(spacing: 16) {
                        // Camera Button
                        Button {
                            MixpanelService.shared.track(event: MixpanelService.Events.takePhotoButtonTapped)
                            showingActionSheet = true
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Take Photo")
                                        .font(.system(size: 18, weight: .semibold))
                                    
                                    Text("Add any context you think is necessary")
                                        .font(.system(size: 14))
                                        .opacity(0.8)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .opacity(0.6)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.3), value: false)
                    }
                    .padding(.horizontal, 28)
                    
                    Spacer()
                    
                    // View Cookbooks Button
                    Button {
                        MixpanelService.shared.track(event: MixpanelService.Events.viewCookbooksButtonTapped)
                        showingCookbooks = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "book")
                                .font(.system(size: 18, weight: .medium))
                            
                            Text("View Cookbooks")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.blue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.bottom, 25)
                }
            }
            .navigationTitle("Preppi AI")
            .navigationBarTitleDisplayMode(.large)
        }
        .confirmationDialog("Select Photo", isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button("Take Photo") {
                sourceType = .camera
                showingImagePicker = true
            }
            
            Button("Choose from Library") {
                sourceType = .photoLibrary
                showingImagePicker = true
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose how you'd like to add your photo")
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: sourceType) { image in
                print("📱 CameraView: Received image from picker, size: \(image.size)")
                
                // Set the image first
                selectedImage = image
                
                // Dismiss the image picker first, then show photo processing
                showingImagePicker = false
                
                print("📱 CameraView: Set selectedImage and dismissed picker, preparing to show photo processing...")
                
                // Wait a bit longer to ensure the sheet is fully dismissed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if selectedImage != nil && !showingPhotoProcessing {
                        print("📱 CameraView: Showing photo processing view")
                        showingPhotoProcessing = true
                    } else if selectedImage == nil {
                        print("❌ CameraView: selectedImage became nil, cannot show photo processing")
                    } else {
                        print("⚠️ CameraView: Photo processing already showing, skipping")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingPhotoProcessing, onDismiss: {
            print("📱 CameraView: PhotoProcessing dismissed, clearing selectedImage")
            selectedImage = nil
        }) {
            if let image = selectedImage {
                PhotoProcessingView(selectedImage: image)
                    .onAppear {
                        print("📱 CameraView: PhotoProcessingView loading with image size: \(image.size)")
                    }
            } else {
                // Fallback in case selectedImage is nil
                ZStack {
                    // Background
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Image")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Please try taking another photo")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Button("Try Again") {
                            showingPhotoProcessing = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    // Close button overlay
                    VStack {
                        HStack {
                            Button("Close") {
                                showingPhotoProcessing = false
                            }
                            .foregroundColor(.blue)
                            .padding()
                            Spacer()
                        }
                        Spacer()
                    }
                }
                .onAppear {
                    print("❌ CameraView: selectedImage is nil when trying to show PhotoProcessingView")
                }
            }
        }
        .fullScreenCover(isPresented: $showingCookbooks) {
            CookbooksListView()
        }
        .onChange(of: appState.shouldNavigateToPhotoProcessing) { _, shouldNavigate in
            if shouldNavigate, let sharedImage = appState.sharedImage {
                print("📸 CameraView: Handling shared image from extension")
                selectedImage = sharedImage
                showingPhotoProcessing = true
                // Clear the shared image state
                appState.clearSharedImage()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerSharedImageCheck"))) { _ in
            print("📸 CameraView: Received trigger to check for shared images")
            // Manually trigger the app's shared image check
            if let app = UIApplication.shared.delegate as? UIApplicationDelegate {
                // This will trigger the checkForSharedImage method
                NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
            }
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(AppState())
}
