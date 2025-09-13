import SwiftUI
import Foundation

class AIRecipeService: ObservableObject {
    @Published var isGenerating = false
    @Published var errorMessage: String?
    
    private let apiKey = ConfigurationService.shared.openAIAPIKey
    private let visionURL = "https://api.openai.com/v1/chat/completions"
    
    /// Analyzes food image and generates complete recipe information
    func generateRecipeFromImage(
        image: UIImage,
        context: String = "",
        servings: Int = 1
    ) async throws -> RecipeAnalysis {
        await MainActor.run {
            isGenerating = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isGenerating = false
            }
        }
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AIRecipeError.imageProcessingFailed
        }
        let base64Image = imageData.base64EncodedString()
        
        // Create the prompt
        let prompt = createVisionPrompt(context: context, servings: servings)
        
        // Prepare the request
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "high"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.7
        ]
        
        guard let url = URL(string: visionURL) else {
            throw AIRecipeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw AIRecipeError.invalidRequest
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIRecipeError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                await MainActor.run {
                    errorMessage = message
                }
                throw AIRecipeError.apiError(message)
            }
            throw AIRecipeError.invalidResponse
        }
        
        do {
            let visionResponse = try JSONDecoder().decode(VisionResponse.self, from: data)
            guard let content = visionResponse.choices.first?.message.content else {
                throw AIRecipeError.parsingError
            }
            
            // Parse the JSON response from GPT-4o
            let recipeAnalysis = try parseRecipeResponse(content)
            return recipeAnalysis
            
        } catch {
            print("❌ Error parsing vision response: \(error)")
            throw AIRecipeError.parsingError
        }
    }
    
    private func createVisionPrompt(context: String, servings: Int) -> String {
        let contextSection = context.isEmpty ? "" : """
        
        Additional Context: \(context)
        """
        
        return """
        Analyze this food image and provide a comprehensive recipe analysis. Return your response as a valid JSON object with the following structure:
        
        {
            "foodIdentification": "Name of the identified food/dish",
            "description": "Brief description of the dish",
            "recipe": {
                "ingredients": [
                    {
                        "item": "ingredient name",
                        "amount": "quantity for \(servings) serving(s)",
                        "unit": "measurement unit"
                    }
                ],
                "instructions": [
                    "Step 1 instruction",
                    "Step 2 instruction"
                ],
                "prepTime": "preparation time in minutes",
                "cookTime": "cooking time in minutes",
                "totalTime": "total time in minutes"
            },
            "nutrition": {
                "calories": total_calories_number,
                "protein": protein_grams_number,
                "carbs": carbs_grams_number,
                "fat": fat_grams_number,
                "fiber": fiber_grams_number,
                "sugar": sugar_grams_number
            },
            "shoppingList": [
                "ingredient 1",
                "ingredient 2"
            ],
            "difficultyRating": difficulty_rating_1_to_10
        }
        
        Requirements:
        1. Identify the food in the image accurately
        2. Scale all ingredients for exactly \(servings) serving(s)
        3. Provide detailed step-by-step cooking instructions
        4. Calculate accurate nutrition information per serving
        5. Create a practical shopping list with just the ingredient names
        6. Rate the cooking difficulty from 1-10 where:
           - 1-2: Very Easy (minimal prep, basic techniques)
           - 3-4: Easy (simple cooking methods, common ingredients)
           - 5-6: Moderate (some skill required, multiple steps)
           - 7-8: Hard (advanced techniques, precise timing)
           - 9-10: Expert (professional techniques, complex processes)
        7. Return ONLY valid JSON without markdown formatting (no ```json or ``` blocks), no additional text\(contextSection)
        """
    }
    
    private func parseRecipeResponse(_ content: String) throws -> RecipeAnalysis {
        // Clean the content to extract just the JSON
        var cleanedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks if present
        if cleanedContent.hasPrefix("```json") {
            cleanedContent = String(cleanedContent.dropFirst(7)) // Remove "```json"
        } else if cleanedContent.hasPrefix("```") {
            cleanedContent = String(cleanedContent.dropFirst(3)) // Remove "```"
        }
        
        if cleanedContent.hasSuffix("```") {
            cleanedContent = String(cleanedContent.dropLast(3)) // Remove trailing "```"
        }
        
        // Final trim after removing markdown
        cleanedContent = cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanedContent.data(using: .utf8) else {
            throw AIRecipeError.parsingError
        }
        
        do {
            let recipeAnalysis = try JSONDecoder().decode(RecipeAnalysis.self, from: data)
            return recipeAnalysis
        } catch {
            print("❌ JSON Parsing Error: \(error)")
            print("❌ Cleaned Content: \(cleanedContent)")
            throw AIRecipeError.parsingError
        }
    }
}

// MARK: - Data Models
struct RecipeAnalysis: Codable {
    let foodIdentification: String
    let description: String
    let recipe: RecipeDetails
    let nutrition: NutritionInfo
    let shoppingList: [String]
    let difficultyRating: Int
}

struct RecipeDetails: Codable {
    let ingredients: [RecipeIngredient]
    let instructions: [String]
    let prepTime: String
    let cookTime: String
    let totalTime: String
}

struct RecipeIngredient: Codable {
    let item: String
    let amount: String
    let unit: String
}

struct NutritionInfo: Codable {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
}

struct VisionResponse: Codable {
    let choices: [VisionChoice]
}

struct VisionChoice: Codable {
    let message: VisionMessage
}

struct VisionMessage: Codable {
    let content: String
}

// MARK: - Error Handling
enum AIRecipeError: Error, LocalizedError {
    case imageProcessingFailed
    case invalidURL
    case invalidRequest
    case invalidResponse
    case apiError(String)
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process the image"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidRequest:
            return "Invalid request format"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return "API Error: \(message)"
        case .parsingError:
            return "Failed to parse response"
        }
    }
}
