import Foundation
import Supabase

class FeedbackService: ObservableObject {
    static let shared = FeedbackService()

    @Published var feedbackList: [Feedback] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared.client
    private let resendAPIKey = ConfigurationService.shared.resendAPIKey

    private init() {
        Task {
            await loadAllFeedback()
        }
    }

    // MARK: - Public Methods

    /// Submit new feedback - saves to database AND sends email
    func submitFeedback(message: String) async throws {
        guard !message.isEmpty else {
            throw FeedbackError.emptyMessage
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            // 1. Save to Supabase database
            let feedbackId = try await saveFeedbackToDatabase(message: message)
            print("✅ Feedback saved to database with ID: \(feedbackId)")

            // 2. Send email via Resend
            try await sendFeedbackEmail(message: message, feedbackId: feedbackId)
            print("✅ Feedback email sent successfully")

            // 3. Reload feedback list
            await loadAllFeedback()

            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }

    /// Load all feedback from database with user votes and interleaved ordering
    @MainActor
    func loadAllFeedback() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load feedback
            let response: [DatabaseFeedback] = try await supabase
                .from("feedback")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value

            // Convert DatabaseFeedback to Feedback models
            var feedbacks = response.compactMap { $0.toFeedback() }

            // Load user votes and attach to feedback items
            let userVotes = try await loadUserVotes()
            for i in 0..<feedbacks.count {
                if let userVote = userVotes.first(where: { $0.feedbackId == feedbacks[i].id }) {
                    feedbacks[i].userVoteType = userVote.voteType
                }
            }

            // Apply interleaved ordering (highest voted alternating with most recent)
            feedbackList = interleaveFeedback(feedbacks)
            print("✅ Loaded \(feedbackList.count) feedback items with interleaved ordering")

            isLoading = false
        } catch {
            print("❌ Error loading feedback: \(error)")
            errorMessage = "Failed to load feedback: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Handle upvote - toggles upvote or switches from downvote
    func upvote(feedbackId: UUID) async throws {
        guard let userId = try? await supabase.auth.session.user.id.uuidString else {
            throw FeedbackError.notAuthenticated
        }

        await MainActor.run {
            isLoading = true
        }

        do {
            // Check current vote status
            let existingVote = try await getUserVote(feedbackId: feedbackId, userId: userId)

            if let vote = existingVote {
                if vote.voteType == .upvote {
                    // Remove upvote
                    try await removeVote(voteId: vote.id, feedbackId: feedbackId, wasUpvote: true)
                } else {
                    // Switch from downvote to upvote
                    try await switchVote(voteId: vote.id, feedbackId: feedbackId, toUpvote: true)
                }
            } else {
                // Add new upvote
                try await addVote(feedbackId: feedbackId, userId: userId, voteType: .upvote, isUpvote: true)
            }

            // Reload feedback
            await loadAllFeedback()

            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }

    /// Handle downvote - toggles downvote or switches from upvote
    func downvote(feedbackId: UUID) async throws {
        guard let userId = try? await supabase.auth.session.user.id.uuidString else {
            throw FeedbackError.notAuthenticated
        }

        await MainActor.run {
            isLoading = true
        }

        do {
            // Check current vote status
            let existingVote = try await getUserVote(feedbackId: feedbackId, userId: userId)

            if let vote = existingVote {
                if vote.voteType == .downvote {
                    // Remove downvote
                    try await removeVote(voteId: vote.id, feedbackId: feedbackId, wasUpvote: false)
                } else {
                    // Switch from upvote to downvote
                    try await switchVote(voteId: vote.id, feedbackId: feedbackId, toUpvote: false)
                }
            } else {
                // Add new downvote
                try await addVote(feedbackId: feedbackId, userId: userId, voteType: .downvote, isUpvote: false)
            }

            // Reload feedback
            await loadAllFeedback()

            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }

    // MARK: - Private Methods

    /// Load user votes for current user
    private func loadUserVotes() async throws -> [UserVote] {
        guard let userId = try? await supabase.auth.session.user.id.uuidString else {
            return []
        }

        let response: [DatabaseUserVote] = try await supabase
            .from("user_votes")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        return response.compactMap { $0.toUserVote() }
    }

    /// Get user's vote for a specific feedback
    private func getUserVote(feedbackId: UUID, userId: String) async throws -> UserVote? {
        let response: [DatabaseUserVote] = try await supabase
            .from("user_votes")
            .select()
            .eq("feedback_id", value: feedbackId.uuidString)
            .eq("user_id", value: userId)
            .execute()
            .value

        return response.first?.toUserVote()
    }

    /// Add a new vote
    private func addVote(feedbackId: UUID, userId: String, voteType: VoteType, isUpvote: Bool) async throws {
        // Create vote record
        struct NewVote: Codable {
            let id: String
            let feedback_id: String
            let user_id: String
            let vote_type: String
        }

        let voteId = UUID()
        let newVote = NewVote(
            id: voteId.uuidString,
            feedback_id: feedbackId.uuidString,
            user_id: userId,
            vote_type: voteType.rawValue
        )

        try await supabase
            .from("user_votes")
            .insert(newVote)
            .execute()

        // Update feedback counts
        let feedback = feedbackList.first(where: { $0.id == feedbackId })
        if isUpvote {
            try await updateVotes(feedbackId: feedbackId, upvotes: (feedback?.upvotes ?? 0) + 1, downvotes: feedback?.downvotes ?? 0)
        } else {
            try await updateVotes(feedbackId: feedbackId, upvotes: feedback?.upvotes ?? 0, downvotes: (feedback?.downvotes ?? 0) + 1)
        }

        print("✅ Added \(voteType.rawValue) for feedback \(feedbackId)")
    }

    /// Remove a vote
    private func removeVote(voteId: UUID, feedbackId: UUID, wasUpvote: Bool) async throws {
        try await supabase
            .from("user_votes")
            .delete()
            .eq("id", value: voteId.uuidString)
            .execute()

        // Update feedback counts
        let feedback = feedbackList.first(where: { $0.id == feedbackId })
        if wasUpvote {
            try await updateVotes(feedbackId: feedbackId, upvotes: max(0, (feedback?.upvotes ?? 0) - 1), downvotes: feedback?.downvotes ?? 0)
        } else {
            try await updateVotes(feedbackId: feedbackId, upvotes: feedback?.upvotes ?? 0, downvotes: max(0, (feedback?.downvotes ?? 0) - 1))
        }

        print("✅ Removed vote for feedback \(feedbackId)")
    }

    /// Switch vote from one type to another
    private func switchVote(voteId: UUID, feedbackId: UUID, toUpvote: Bool) async throws {
        // Update vote type
        try await supabase
            .from("user_votes")
            .update(["vote_type": toUpvote ? "upvote" : "downvote"])
            .eq("id", value: voteId.uuidString)
            .execute()

        // Update feedback counts (decrement old, increment new)
        let feedback = feedbackList.first(where: { $0.id == feedbackId })
        if toUpvote {
            // Switching from downvote to upvote
            try await updateVotes(
                feedbackId: feedbackId,
                upvotes: (feedback?.upvotes ?? 0) + 1,
                downvotes: max(0, (feedback?.downvotes ?? 0) - 1)
            )
        } else {
            // Switching from upvote to downvote
            try await updateVotes(
                feedbackId: feedbackId,
                upvotes: max(0, (feedback?.upvotes ?? 0) - 1),
                downvotes: (feedback?.downvotes ?? 0) + 1
            )
        }

        print("✅ Switched vote for feedback \(feedbackId)")
    }

    /// Update vote counts in feedback table
    private func updateVotes(feedbackId: UUID, upvotes: Int, downvotes: Int) async throws {
        try await supabase
            .from("feedback")
            .update([
                "upvotes": upvotes,
                "downvotes": downvotes
            ])
            .eq("id", value: feedbackId.uuidString)
            .execute()
    }

    /// Interleave feedback: alternate between highest voted and most recent
    private func interleaveFeedback(_ feedbacks: [Feedback]) -> [Feedback] {
        // Sort by net votes (highest first)
        let byVotes = feedbacks.sorted { $0.netVotes > $1.netVotes }

        // Sort by date (most recent first)
        let byRecent = feedbacks.sorted { $0.createdAt > $1.createdAt }

        var result: [Feedback] = []
        var usedIds: Set<UUID> = []

        let maxCount = feedbacks.count
        var voteIndex = 0
        var recentIndex = 0

        // Interleave: 1 from votes, 1 from recent
        while result.count < maxCount {
            // Add from highest voted if available
            if voteIndex < byVotes.count {
                let item = byVotes[voteIndex]
                if !usedIds.contains(item.id) {
                    result.append(item)
                    usedIds.insert(item.id)
                }
                voteIndex += 1
            }

            // Add from most recent if available
            if result.count < maxCount && recentIndex < byRecent.count {
                let item = byRecent[recentIndex]
                if !usedIds.contains(item.id) {
                    result.append(item)
                    usedIds.insert(item.id)
                }
                recentIndex += 1
            }
        }

        return result
    }

    private func saveFeedbackToDatabase(message: String) async throws -> UUID {
        let feedbackId = UUID()
        let userId = try? await supabase.auth.session.user.id.uuidString

        struct NewFeedback: Codable {
            let id: String
            let feedback_text: String
            let upvotes: Int
            let downvotes: Int
            let user_id: String
        }

        let newFeedback = NewFeedback(
            id: feedbackId.uuidString,
            feedback_text: message,
            upvotes: 0,
            downvotes: 0,
            user_id: userId ?? ""
        )

        do {
            try await supabase
                .from("feedback")
                .insert(newFeedback)
                .execute()

            return feedbackId
        } catch {
            print("❌ Error saving feedback to database: \(error)")
            throw FeedbackError.databaseError(error.localizedDescription)
        }
    }

    private func sendFeedbackEmail(message: String, feedbackId: UUID) async throws {
        guard !resendAPIKey.isEmpty else {
            print("⚠️ Resend API key not configured, skipping email")
            return
        }

        let url = URL(string: "https://api.resend.com/emails")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(resendAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let emailBody: [String: Any] = [
            "from": "Preppi AI Feedback <onboarding@resend.dev>",
            "to": ["oduduabasiav@gmail.com"],
            "subject": "New Feedback from Preppi AI User",
            "html": """
            <h2>New Feedback Received</h2>
            <p><strong>Feedback ID:</strong> \(feedbackId)</p>
            <p><strong>Submitted:</strong> \(Date().formatted(date: .long, time: .standard))</p>
            <hr>
            <p><strong>Message:</strong></p>
            <p>\(message.replacingOccurrences(of: "\n", with: "<br>"))</p>
            <hr>
            <p><em>Sent from Preppi AI Feedback System</em></p>
            """
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: emailBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedbackError.emailFailed("Invalid response")
        }

        if httpResponse.statusCode != 200 {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Email sending failed: \(errorString)")
            throw FeedbackError.emailFailed(errorString)
        }

        print("✅ Email sent successfully via Resend")
    }
}

// MARK: - Feedback Errors
enum FeedbackError: LocalizedError {
    case emptyMessage
    case databaseError(String)
    case emailFailed(String)
    case updateFailed
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .emptyMessage:
            return "Please enter your feedback before submitting."
        case .databaseError(let message):
            return "Database error: \(message)"
        case .emailFailed(let message):
            return "Email sending failed: \(message)"
        case .updateFailed:
            return "Failed to update votes. Please try again."
        case .notAuthenticated:
            return "You must be logged in to vote."
        }
    }
}
