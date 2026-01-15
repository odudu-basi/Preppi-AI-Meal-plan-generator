import SwiftUI

struct ExerciseLoggingSheet: View {
    @Binding var exerciseDescription: String
    let selectedDate: Date
    let onSubmit: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                        .padding(.top, 20)

                    Text("Log Your Exercise")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Describe your workout and we'll analyze it")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                // Text editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercise Description")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ZStack(alignment: .topLeading) {
                        if exerciseDescription.isEmpty {
                            Text("e.g., I ran 5 miles in 45 minutes, did 50 push-ups, and 100 sit-ups")
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                        }

                        TextEditor(text: $exerciseDescription)
                            .focused($isTextFieldFocused)
                            .frame(minHeight: 150)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .scrollContentBackground(.hidden)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Submit button
                Button(action: {
                    onSubmit()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Analyze & Log Exercise")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(exerciseDescription.isEmpty ? Color.gray : Color.orange)
                    )
                }
                .disabled(exerciseDescription.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Auto-focus the text field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
}

#Preview {
    ExerciseLoggingSheet(
        exerciseDescription: .constant(""),
        selectedDate: Date(),
        onSubmit: {},
        onCancel: {}
    )
}
