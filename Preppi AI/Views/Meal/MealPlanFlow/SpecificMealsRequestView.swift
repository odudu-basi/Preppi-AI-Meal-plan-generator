import SwiftUI

struct SpecificMealsRequestView: View {
    @Binding var flowData: MealPlanFlowData
    let onContinue: () -> Void

    @State private var mealRequests: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        // Icon
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "text.bubble.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.orange)
                            )
                            .padding(.top, 20)

                        // Title
                        Text("Any specific meal requests?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        // Subtitle
                        Text("Tell us if there's any specific meals you'd like to include (optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    // Text input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example: \"I'd like to have grilled salmon on Monday\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        TextEditor(text: $mealRequests)
                            .frame(height: 150)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isTextFieldFocused ? Color.orange : Color.gray.opacity(0.3), lineWidth: 1.5)
                                    )
                            )
                            .focused($isTextFieldFocused)
                            .padding(.horizontal, 20)
                    }

                    // Helper text
                    if !mealRequests.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Request noted")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }

                    // Bottom spacing
                    Color.clear.frame(height: 100)
                }
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside
                isTextFieldFocused = false
            }

            // Continue button
            Button(action: {
                // Dismiss keyboard first
                isTextFieldFocused = false

                // Save the meal requests
                flowData.specificMealRequests = mealRequests

                // Short delay to let keyboard dismiss smoothly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onContinue()
                }
            }) {
                Text("Continue")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.orange)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Pre-load any previously entered text
            if !flowData.specificMealRequests.isEmpty {
                mealRequests = flowData.specificMealRequests
            }
        }
    }
}
