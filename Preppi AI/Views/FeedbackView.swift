import SwiftUI

struct FeedbackView: View {
    @StateObject private var feedbackService = FeedbackService.shared
    @State private var showSubmissionSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Submit Feedback Button
                        Button(action: {
                            showSubmissionSheet = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)

                                Text("Submit Feedback")
                                    .font(.headline)
                                    .fontWeight(.semibold)
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
                            .cornerRadius(16)
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Feedback List
                        if feedbackService.isLoading && feedbackService.feedbackList.isEmpty {
                            loadingView
                        } else if feedbackService.feedbackList.isEmpty {
                            emptyStateView
                        } else {
                            feedbackListView
                        }
                    }
                    .padding(.bottom, 30)
                }
                .refreshable {
                    await feedbackService.loadAllFeedback()
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showSubmissionSheet) {
            FeedbackSubmissionSheet()
                .environmentObject(feedbackService)
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                .scaleEffect(1.5)

            Text("Loading feedback...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Feedback Yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("Be the first to share your thoughts!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 40)
    }

    // MARK: - Feedback List
    private var feedbackListView: some View {
        LazyVStack(spacing: 16) {
            ForEach(feedbackService.feedbackList) { feedback in
                FeedbackCard(feedback: feedback)
                    .environmentObject(feedbackService)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Feedback Card Component
struct FeedbackCard: View {
    let feedback: Feedback
    @EnvironmentObject var feedbackService: FeedbackService
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Anonymous + Timestamp
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text("Anonymous")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(feedback.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Feedback Text
            Text(feedback.feedbackText)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            // Vote Buttons
            HStack(spacing: 20) {
                // Upvote Button
                Button(action: {
                    Task {
                        try? await feedbackService.upvote(feedbackId: feedback.id)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: feedback.userVoteType == .upvote ? "arrow.up.circle.fill" : "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(feedback.userVoteType == .upvote ? .green : .secondary)

                        Text("\(feedback.upvotes)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(feedback.userVoteType == .upvote ?
                                Color.green.opacity(colorScheme == .dark ? 0.3 : 0.2) :
                                Color.green.opacity(colorScheme == .dark ? 0.15 : 0.08))
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Downvote Button
                Button(action: {
                    Task {
                        try? await feedbackService.downvote(feedbackId: feedback.id)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: feedback.userVoteType == .downvote ? "arrow.down.circle.fill" : "arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(feedback.userVoteType == .downvote ? .red : .secondary)

                        Text("\(feedback.downvotes)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(feedback.userVoteType == .downvote ?
                                Color.red.opacity(colorScheme == .dark ? 0.3 : 0.2) :
                                Color.red.opacity(colorScheme == .dark ? 0.15 : 0.08))
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(
                    color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
}

#Preview {
    FeedbackView()
}
