import SwiftUI

struct PhotoProcessingView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedImage: UIImage
    @State private var contextText: String = ""
    @State private var servings: Int = 1
    @StateObject private var aiRecipeService = AIRecipeService()
    @State private var showingRecipeResult = false
    @State private var recipeAnalysis: RecipeAnalysis?
    
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
                .onTapGesture {
                    // Dismiss keyboard when tapping background
                    hideKeyboard()
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Image Display Container
                        VStack {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                .onTapGesture {
                                    hideKeyboard()
                                }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        
                        // Context Text Box
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Insert context for more accuracy", text: $contextText, axis: .vertical)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.body)
                                .foregroundColor(contextText.isEmpty ? .gray : .primary)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal, 24)
                        
                        // Servings Control
                        VStack(spacing: 12) {
                            Text("Servings")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 20) {
                                // Minus Button
                                Button {
                                    hideKeyboard()
                                    if servings > 1 {
                                        servings -= 1
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(servings > 1 ? .blue : .gray)
                                }
                                .disabled(servings <= 1)
                                
                                // Servings Display
                                Text("\(servings)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .frame(minWidth: 40)
                                
                                // Plus Button
                                Button {
                                    hideKeyboard()
                                    if servings < 10 {
                                        servings += 1
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(servings < 10 ? .blue : .gray)
                                }
                                .disabled(servings >= 10)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6).opacity(0.5))
                                .onTapGesture {
                                    hideKeyboard()
                                }
                        )
                        .padding(.horizontal, 20)
                        
                        // Get Recipe Button
                        Button {
                            MixpanelService.shared.track(
                                event: MixpanelService.Events.photoProcessingStarted,
                                properties: [
                                    MixpanelService.Properties.servings: servings,
                                    MixpanelService.Properties.contextProvided: !contextText.isEmpty
                                ]
                            )
                            generateRecipe()
                        } label: {
                            HStack {
                                if aiRecipeService.isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                    Text("Analyzing...")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                } else {
                                    Text("Get Recipe")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .green.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(aiRecipeService.isGenerating)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Error Message
                        if let errorMessage = aiRecipeService.errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.orange)
                                
                                Text("Recipe Generation Failed")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text(errorMessage)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button("Try Again") {
                                    generateRecipe()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Bottom spacing for safe area
                        Color.clear.frame(height: 60)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                }
                .clipped() // Ensure content doesn't overflow
            }
            .navigationTitle("Process Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        print("📱 PhotoProcessingView: Back button tapped, dismissing...")
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.body)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingRecipeResult) {
            if let analysis = recipeAnalysis {
                RecipeResultView(
                    recipeAnalysis: analysis,
                    originalImage: selectedImage,
                    servings: servings
                )
            }
        }
        .onChange(of: showingRecipeResult) { isShowing in
            // If recipe result is dismissed, also dismiss photo processing
            if !isShowing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func generateRecipe() {
        hideKeyboard() // Dismiss keyboard before starting
        
        Task {
            do {
                print("🔄 Starting recipe generation...")
                print("📸 Image size: \(selectedImage.size)")
                print("📝 Context: '\(contextText)'")
                print("👥 Servings: \(servings)")
                
                let analysis = try await aiRecipeService.generateRecipeFromImage(
                    image: selectedImage,
                    context: contextText.trimmingCharacters(in: .whitespacesAndNewlines),
                    servings: servings
                )
                
                await MainActor.run {
                    MixpanelService.shared.track(
                        event: MixpanelService.Events.recipeGeneratedFromPhoto,
                        properties: [
                            MixpanelService.Properties.recipeName: analysis.foodIdentification,
                            MixpanelService.Properties.servings: servings,
                            MixpanelService.Properties.difficultyRating: analysis.difficultyRating,
                            MixpanelService.Properties.contextProvided: !contextText.isEmpty
                        ]
                    )
                    
                    recipeAnalysis = analysis
                    showingRecipeResult = true
                }
                
                print("✅ Recipe generation completed successfully")
                print("🍽️ Identified food: \(analysis.foodIdentification)")
                
            } catch {
                print("❌ Recipe generation failed: \(error)")
                await MainActor.run {
                    aiRecipeService.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    PhotoProcessingView(selectedImage: UIImage(systemName: "photo") ?? UIImage())
}
