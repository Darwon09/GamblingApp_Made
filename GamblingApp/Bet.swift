//
//  Bet.swift
//  GamblingApp
//
//  Created by Darren Ich on 12/5/25.
//

import Foundation
import FirebaseFirestore
import Combine

struct Bet: Identifiable, Codable, Sendable {
    @DocumentID var id: String?
    var creatorId: String
    var creatorUsername: String
    var participantId: String
    var participantUsername: String
    var title: String
    var description: String
    var amount: Double
    var status: BetStatus
    var winnerId: String?
    var createdAt: Date
    var acceptedAt: Date?
    var completedAt: Date?

    enum BetStatus: String, Codable, Sendable {
        case pending = "pending"
        case accepted = "accepted"
        case rejected = "rejected"
        case active = "active"
        case completed = "completed"
    }

    var isActive: Bool {
        return status == .active || status == .accepted
    }

    var isPending: Bool {
        return status == .pending
    }

    var isCompleted: Bool {
        return status == .completed
    }

    func isCreator(userId: String) -> Bool {
        return creatorId == userId
    }

    func isParticipant(userId: String) -> Bool {
        return participantId == userId
    }

    func opponentUsername(for userId: String) -> String {
        return isCreator(userId: userId) ? participantUsername : creatorUsername
    }
}
