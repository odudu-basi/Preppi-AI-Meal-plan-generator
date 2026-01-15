import SwiftUI

struct FeedbackSubmissionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var feedbackService: FeedbackService
    @FocusState private var isTextEditorFocused: Bool

    @State private var feedbackText = ""
    @State private var isSubmitting = false
    @State private var showSuccessMessage = false
    @State private var showErrorMessage = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)

                        Text("Share Your Feedback")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Help us improve Preppi AI! Share your ideas, suggestions, or report any issues you've encountered.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)

                    // Feedback Input Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Feedback")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        ZStack(alignment: .topLeading) {
                            if feedbackText.isEmpty {
                                Text("Tell us what's on your mind...\n\nWhat features would you like to see? Found a bug? We're listening!")
                                    .font(.body)
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }

                            TextEditor(text: $feedbackText)
                                .font(.body)
                                .foregroundColor(.primary)
                                .frame(minHeight: 180)
                                .scrollContentBackground(.hidden)
                                .focused($isTextEditorFocused)
                        }
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)

                    // Submit Button
                    Button(action: submitFeedback) {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Sending...")
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Submit Feedback")
                            }
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: feedbackText.isEmpty ? [.gray, .gray.opacity(0.8)] : [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: feedbackText.isEmpty ? .clear : .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(feedbackText.isEmpty || isSubmitting)
                    .opacity(feedbackText.isEmpty ? 0.6 : 1.0)
                    .padding(.horizontal, 20)

                    // Success/Error Messages
                    if showSuccessMessage {
                        successMessageView
                    }

                    if showErrorMessage {
                        errorMessageView
                    }

                    Spacer()
                }
                .padding(.bottom, 30)
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextEditorFocused = false
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }

                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isTextEditorFocused = false
                        }
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                    }
                }
            }
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Success Message
    private var successMessageView: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text("Feedback Sent!")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("Thank you for helping us improve!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Error Message
    private var errorMessageView: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.red)

            VStack(alignment: .leading, spacing: 4) {
                Text("Failed to Send")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Submit Feedback
    private func submitFeedback() {
        guard !feedbackText.isEmpty else { return }

        isSubmitting = true
        showSuccessMessage = false
        showErrorMessage = false

        Task {
            do {
                try await feedbackService.submitFeedback(message: feedbackText)

                await MainActor.run {
                    isSubmitting = false
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showSuccessMessage = true
                    }

                    // Track feedback submission
                    MixpanelService.shared.track(
                        event: "feedback_submitted",
                        properties: ["feedback_length": feedbackText.count]
                    )

                    // Close sheet after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showErrorMessage = true
                    }

                    // Hide error message after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                            showErrorMessage = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    FeedbackSubmissionSheet()
        .environmentObject(FeedbackService.shared)
}
