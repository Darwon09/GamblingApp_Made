//
//  BetDetailView.swift
//  GamblingApp
//
//  Created by Darren Ich on 12/5/25.
//

import SwiftUI
import FirebaseAuth

struct BetDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var betManager = BetManager.shared
    let bet: Bet

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isProcessing = false

    let primaryGreen = Color(red: 41/255, green: 87/255, blue: 50/255)
    let lightGray = Color(red: 242/255, green: 242/255, blue: 247/255)

    var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    var isCreator: Bool {
        bet.creatorId == currentUserId
    }

    var isParticipant: Bool {
        bet.participantId == currentUserId
    }

    var opponentName: String {
        isCreator ? bet.participantUsername : bet.creatorUsername
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(primaryGreen.opacity(0.2))
                                .frame(width: 80, height: 80)
                            Text(String(opponentName.prefix(1)).uppercased())
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(primaryGreen)
                        }

                        Text("vs. \(opponentName)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)

                        Text(isCreator ? "You created this bet" : "Bet from \(bet.creatorUsername)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 8) {
                        Text("Bet Amount")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        Text("$\(String(format: "%.0f", bet.amount))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(primaryGreen)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(primaryGreen.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What's the bet?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            Text(bet.title)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                        }

                        if !bet.description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                Text(bet.description)
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Status")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            HStack {
                                Image(systemName: statusIcon)
                                    .font(.system(size: 14))
                                Text(bet.status.rawValue.capitalized)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(statusColor.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)

                    if isParticipant && bet.isPending {
                        VStack(spacing: 12) {
                            Button(action: acceptBet) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Accept Bet")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(primaryGreen)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessing)

                            Button(action: declineBet) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Decline Bet")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessing)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    } else if isCreator && bet.isPending {
                        VStack(spacing: 8) {
                            Text("Waiting for \(bet.participantUsername) to respond")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)

                            Button(action: cancelBet) {
                                Text("Cancel Bet")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .disabled(isProcessing)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    } else if bet.isActive {
                        VStack(spacing: 12) {
                            Text("Who won the bet?")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.bottom, 4)

                            Button(action: { declareWinner(userId: currentUserId) }) {
                                HStack {
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 20))
                                    Text("I Won!")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(primaryGreen)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessing)

                            Button(action: {
                                let opponentId = isCreator ? bet.participantId : bet.creatorId
                                declareWinner(userId: opponentId)
                            }) {
                                HStack {
                                    Image(systemName: "hand.thumbsup.fill")
                                        .font(.system(size: 20))
                                    Text("\(opponentName) Won")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.orange)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessing)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    } else if bet.isCompleted {
                        VStack(spacing: 8) {
                            if let winnerId = bet.winnerId {
                                let winnerName = winnerId == bet.creatorId ? bet.creatorUsername : bet.participantUsername
                                let didIWin = winnerId == currentUserId

                                HStack {
                                    Image(systemName: didIWin ? "trophy.fill" : "flag.checkered")
                                        .font(.system(size: 24))
                                        .foregroundColor(didIWin ? Color(red: 218/255, green: 165/255, blue: 32/255) : .gray)

                                    Text(didIWin ? "You Won!" : "\(winnerName) Won")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(didIWin ? primaryGreen : .gray)
                                }
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(didIWin ? primaryGreen.opacity(0.1) : Color.gray.opacity(0.1))
                                .cornerRadius(12)

                                Text(didIWin ? "You won $\(String(format: "%.0f", bet.amount))!" : "Better luck next time!")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Bet Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Bet Action", isPresented: $showAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
    }

    var statusIcon: String {
        switch bet.status {
        case .pending:
            return "clock"
        case .accepted, .active:
            return "checkmark.circle.fill"
        case .completed:
            return "flag.checkered"
        case .rejected:
            return "xmark.circle.fill"
        }
    }

    var statusColor: Color {
        switch bet.status {
        case .pending:
            return .orange
        case .accepted, .active:
            return primaryGreen
        case .completed:
            return .blue
        case .rejected:
            return .red
        }
    }

    func acceptBet() {
        guard let betId = bet.id else { return }

        isProcessing = true
        betManager.acceptBet(betId: betId) { result in
            isProcessing = false
            switch result {
            case .success:
                alertMessage = "Bet accepted! Good luck!"
                showAlert = true
            case .failure(let error):
                alertMessage = "Failed to accept bet: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    func declineBet() {
        guard let betId = bet.id else { return }

        isProcessing = true
        betManager.rejectBet(betId: betId) { result in
            isProcessing = false
            switch result {
            case .success:
                alertMessage = "Bet declined"
                showAlert = true
            case .failure(let error):
                alertMessage = "Failed to decline bet: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    func cancelBet() {
        guard let betId = bet.id else { return }

        isProcessing = true
        betManager.deleteBet(betId: betId) { result in
            isProcessing = false
            switch result {
            case .success:
                alertMessage = "Bet cancelled"
                showAlert = true
            case .failure(let error):
                alertMessage = "Failed to cancel bet: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    func declareWinner(userId: String) {
        guard let betId = bet.id else { return }

        isProcessing = true
        betManager.completeBetWithPayout(
            betId: betId,
            bet: bet,
            winnerId: userId
        ) { result in
            isProcessing = false
            switch result {
            case .success:
                let didIWin = userId == currentUserId
                alertMessage = didIWin
                    ? "Congratulations! You won $\(String(format: "%.0f", bet.amount))!"
                    : "Bet completed. Better luck next time!"
                showAlert = true
            case .failure(let error):
                alertMessage = "Failed to complete bet: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

#Preview {
    BetDetailView(bet: Bet(
        id: "1",
        creatorId: "user1",
        creatorUsername: "John",
        participantId: "user2",
        participantUsername: "Jane",
        title: "Lakers will win tonight",
        description: "NBA Finals Game 7",
        amount: 100,
        status: .pending,
        winnerId: nil,
        createdAt: Date(),
        acceptedAt: nil,
        completedAt: nil
    ))
}
