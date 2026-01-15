//
//  MealDetailsInputView.swift
//  Preppi AI
//
//  Created by AI Assistant on 11/20/25.
//

import SwiftUI

struct MealDetailsInputView: View {
    let mealImage: UIImage
    let currentAnalysis: MealAnalysisResult
    let onRefine: (String) -> Void
    let onCancel: () -> Void

    @State private var additionalDetails: String = ""
    @State private var showCheckmark: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                // Tap gesture background to dismiss keyboard
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isTextFieldFocused = false
                    }

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Add Missing Details")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("Help us refine the calorie count by adding any missing information about your meal")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    .onTapGesture {
                        isTextFieldFocused = false
                    }

                // Meal image preview
                Image(uiImage: mealImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                    .padding(.horizontal, 20)
                    .onTapGesture {
                        isTextFieldFocused = false
                    }

                // Current meal name
                Text(currentAnalysis.mealName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .onTapGesture {
                        isTextFieldFocused = false
                    }

                // Text field with green border
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional Details")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    ZStack(alignment: .topLeading) {
                        // Placeholder
                        if additionalDetails.isEmpty {
                            Text("E.g., \"Extra cheese\", \"Large portion\", \"With sauce on the side\"...")
                                .font(.system(size: 16))
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $additionalDetails)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .background(Color(.systemBackground))
                            .focused($isTextFieldFocused)
                            .onChange(of: additionalDetails) { oldValue, newValue in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showCheckmark = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                }
                            }
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        isTextFieldFocused = false
                                    }
                                }
                            }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
                }
                .padding(.horizontal, 20)

                Spacer()
                    .onTapGesture {
                        isTextFieldFocused = false
                    }

                // Checkmark button (only shows when text is entered)
                if showCheckmark {
                    Button(action: {
                        isTextFieldFocused = false
                        let details = additionalDetails.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !details.isEmpty {
                            onRefine(details)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .semibold))

                            Text("Refine Calories")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .transition(.scale.combined(with: .opacity))
                }

                Color.clear.frame(height: 20)
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                }
                .background(Color(.systemBackground))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: onCancel) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .onAppear {
            // Auto-focus the text field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}

#Preview {
    MealDetailsInputView(
        mealImage: UIImage(systemName: "photo") ?? UIImage(),
        currentAnalysis: MealAnalysisResult(
            mealName: "Burger Bowl",
            description: "Seared beef patty over greens",
            macros: Macros(
                protein: 45.0,
                carbohydrates: 30.0,
                fat: 20.0,
                fiber: 5.0,
                sugar: 3.0,
                sodium: 890.0
            ),
            calories: 500,
            healthScore: 7
        ),
        onRefine: { details in
            print("Refining with: \(details)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}
