import Foundation

// MARK: - Feedback Data Model
struct Feedback: Identifiable, Codable, Hashable {
    let id: UUID
    let feedbackText: String
    let upvotes: Int
    let downvotes: Int
    let createdAt: Date
    let userId: String? // Optional, for tracking but displayed as "Anonymous"
    var userVoteType: VoteType? // Track current user's vote on this feedback

    enum CodingKeys: String, CodingKey {
        case id
        case feedbackText = "feedback_text"
        case upvotes
        case downvotes
        case createdAt = "created_at"
        case userId = "user_id"
    }

    // Computed property for net votes
    var netVotes: Int {
        upvotes - downvotes
    }

    // Format timestamp for display
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Vote Type
enum VoteType: String, Codable {
    case upvote
    case downvote
}

// MARK: - User Vote Model
struct UserVote: Identifiable, Codable {
    let id: UUID
    let feedbackId: UUID
    let userId: String
    let voteType: VoteType
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case feedbackId = "feedback_id"
        case userId = "user_id"
        case voteType = "vote_type"
        case createdAt = "created_at"
    }
}

// MARK: - Database User Vote (for Supabase)
struct DatabaseUserVote: Codable {
    let id: UUID
    let feedback_id: UUID
    let user_id: String
    let vote_type: String
    let created_at: String

    func toUserVote() -> UserVote? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: created_at),
              let voteType = VoteType(rawValue: vote_type) else {
            return nil
        }

        return UserVote(
            id: id,
            feedbackId: feedback_id,
            userId: user_id,
            voteType: voteType,
            createdAt: date
        )
    }
}

// MARK: - Database Feedback (for Supabase)
struct DatabaseFeedback: Codable {
    let id: UUID
    let feedback_text: String
    let upvotes: Int
    let downvotes: Int
    let created_at: String
    let user_id: String?

    // Convert to Feedback model
    func toFeedback() -> Feedback? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: created_at) else {
            return nil
        }

        return Feedback(
            id: id,
            feedbackText: feedback_text,
            upvotes: upvotes,
            downvotes: downvotes,
            createdAt: date,
            userId: user_id,
            userVoteType: nil
        )
    }
}
