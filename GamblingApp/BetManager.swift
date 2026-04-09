//
//  BetManager.swift
//  GamblingApp
//
//  Created by Darren Ich on 12/5/25.
//

import Foundation
@preconcurrency import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class BetManager: ObservableObject {
    static let shared = BetManager()
    private let db = Firestore.firestore()

    @Published var userBets: [Bet] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var userCoins: Int = 0
    @Published var canClaimDailyCoins: Bool = false
    @Published var timeUntilNextClaim: String = "Loading..."
    @Published var friendsList: [AppUser] = []
    @Published var friendRequests: [FriendRequest] = []

    private var creatorBets: [Bet] = []
    private var participantBets: [Bet] = []

    private init() {}



    /// Create a new bet
    func createBet(
        participantId: String,
        participantUsername: String,
        title: String,
        description: String,
        amount: Double,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        print("Creating bet: \(title)")

        guard let currentUser = Auth.auth().currentUser else {
            print("No current user for bet creation")
            completion(.failure(NSError(domain: "BetManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        let currentUserId = currentUser.uid
        let currentUserEmail = currentUser.email
        let database = db

        print("Current user ID: \(currentUserId)")

        database.collection("users").document(currentUserId).getDocument { document, error in
            if let error = error {
                print("Error fetching creator username: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            let creatorUsername = document?.data()?["username"] as? String ?? currentUserEmail ?? "Unknown"
            print("Creator username: \(creatorUsername)")

            let betData: [String: Any] = [
                "creatorId": currentUserId,
                "creatorUsername": creatorUsername,
                "participantId": participantId,
                "participantUsername": participantUsername,
                "title": title,
                "description": description,
                "amount": amount,
                "status": Bet.BetStatus.pending.rawValue,
                "winnerId": NSNull(),
                "createdAt": Timestamp(date: Date()),
                "acceptedAt": NSNull(),
                "completedAt": NSNull()
            ]

            print("Bet data prepared: \(betData)")

            database.collection("bets").addDocument(data: betData) { error in
                if let error = error {
                    print("Error saving bet to Firestore: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Bet saved to Firestore successfully!")
                    completion(.success("Bet created successfully!"))
                }
            }
        }
    }

    // MARK: - Fetch Bets

    func fetchUserBets() {
        print("fetchUserBets called")

        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "User not authenticated"
            print("No current user for fetching bets")
            return
        }

        print("Fetching bets for user: \(currentUser.uid)")

        isLoading = true

        db.collection("bets")
            .whereField("creatorId", isEqualTo: currentUser.uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching creator bets: \(error.localizedDescription)")
                    Task { @MainActor in
                        self.errorMessage = "Error fetching creator bets: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                    return
                }

                let bets = querySnapshot?.documents.compactMap { document -> Bet? in
                    try? document.data(as: Bet.self)
                } ?? []

                print("Fetched \(bets.count) creator bets")

                Task { @MainActor in
                    self.creatorBets = bets
                    self.mergeAndUpdateBets()
                }
            }

        db.collection("bets")
            .whereField("participantId", isEqualTo: currentUser.uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching participant bets: \(error.localizedDescription)")
                    Task { @MainActor in
                        self.errorMessage = "Error fetching participant bets: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                    return
                }

                let bets = querySnapshot?.documents.compactMap { document -> Bet? in
                    try? document.data(as: Bet.self)
                } ?? []

                print("Fetched \(bets.count) participant bets")

                Task { @MainActor in
                    self.participantBets = bets
                    self.mergeAndUpdateBets()
                }
            }
    }

    private func mergeAndUpdateBets() {
        let allBets = creatorBets + participantBets
        let uniqueBets = Array(Set(allBets.compactMap { $0.id }))
            .compactMap { id in allBets.first(where: { $0.id == id }) }
            .sorted { $0.createdAt > $1.createdAt }

        print("Total unique bets: \(uniqueBets.count)")
        userBets = uniqueBets
        isLoading = false
    }

    func fetchActiveBets(completion: @escaping ([Bet]) -> Void) {
        guard let currentUser = Auth.auth().currentUser else { return }

        let group = DispatchGroup()
        var allBets: [Bet] = []

        group.enter()
        db.collection("bets")
            .whereField("creatorId", isEqualTo: currentUser.uid)
            .whereField("status", in: [Bet.BetStatus.active.rawValue, Bet.BetStatus.accepted.rawValue])
            .getDocuments { querySnapshot, error in
                if let documents = querySnapshot?.documents {
                    let bets = documents.compactMap { try? $0.data(as: Bet.self) }
                    allBets.append(contentsOf: bets)
                }
                group.leave()
            }

        group.enter()
        db.collection("bets")
            .whereField("participantId", isEqualTo: currentUser.uid)
            .whereField("status", in: [Bet.BetStatus.active.rawValue, Bet.BetStatus.accepted.rawValue])
            .getDocuments { querySnapshot, error in
                if let documents = querySnapshot?.documents {
                    let bets = documents.compactMap { try? $0.data(as: Bet.self) }
                    allBets.append(contentsOf: bets)
                }
                group.leave()
            }

        group.notify(queue: .main) {
            let uniqueBets = Array(Set(allBets.map { $0.id }))
                .compactMap { id in allBets.first(where: { $0.id == id }) }
                .sorted { ($0.createdAt) > ($1.createdAt) }
            completion(uniqueBets)
        }
    }

    func fetchPendingBets(completion: @escaping ([Bet]) -> Void) {
        guard let currentUser = Auth.auth().currentUser else { return }

        db.collection("bets")
            .whereField("participantId", isEqualTo: currentUser.uid)
            .whereField("status", isEqualTo: Bet.BetStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching pending bets: \(error)")
                    completion([])
                    return
                }

                let bets = querySnapshot?.documents.compactMap { document -> Bet? in
                    try? document.data(as: Bet.self)
                } ?? []

                completion(bets)
            }
    }

    // MARK: - Update Bet Status

    func acceptBet(betId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("Accepting bet: \(betId)")

        db.collection("bets").document(betId).updateData([
            "status": Bet.BetStatus.accepted.rawValue,
            "acceptedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error accepting bet: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("Bet accepted successfully! Status changed to 'accepted'")
                completion(.success(()))
            }
        }
    }

    func rejectBet(betId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("Rejecting bet: \(betId)")

        db.collection("bets").document(betId).updateData([
            "status": Bet.BetStatus.rejected.rawValue
        ]) { error in
            if let error = error {
                print("Error rejecting bet: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("Bet rejected successfully! Status changed to 'rejected'")
                completion(.success(()))
            }
        }
    }

    func activateBet(betId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("bets").document(betId).updateData([
            "status": Bet.BetStatus.active.rawValue
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func completeBet(betId: String, winnerId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("bets").document(betId).updateData([
            "status": Bet.BetStatus.completed.rawValue,
            "winnerId": winnerId,
            "completedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func completeBetWithPayout(betId: String, bet: Bet, winnerId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("Completing bet with payout - Winner: \(winnerId)")

        let database = db
        let loserId = winnerId == bet.creatorId ? bet.participantId : bet.creatorId
        let amount = Int(bet.amount)

        print("Bet amount: \(amount)")
        print("Winner ID: \(winnerId)")
        print("Loser ID: \(loserId)")

        database.collection("bets").document(betId).updateData([
            "status": Bet.BetStatus.completed.rawValue,
            "winnerId": winnerId,
            "completedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error completing bet: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            print("Bet marked as completed")

            let group = DispatchGroup()
            var updateError: Error?

            group.enter()
            database.collection("users").document(winnerId).getDocument { document, error in
                if let error = error {
                    print("Error fetching winner's coins: \(error.localizedDescription)")
                    updateError = error
                    group.leave()
                    return
                }

                let currentCoins = (document?.data()?["coins"] as? Int) ?? 0
                let newCoins = currentCoins + amount

                print("Winner's coins: \(currentCoins) → \(newCoins) (+\(amount))")

                database.collection("users").document(winnerId).updateData([
                    "coins": newCoins
                ]) { error in
                    if let error = error {
                        print("Error updating winner's coins: \(error.localizedDescription)")
                        updateError = error
                    } else {
                        print("Winner's coins updated")
                    }
                    group.leave()
                }
            }


            group.enter()
            database.collection("users").document(loserId).getDocument { document, error in
                if let error = error {
                    print("Error fetching loser's coins: \(error.localizedDescription)")
                    updateError = error
                    group.leave()
                    return
                }

                let currentCoins = (document?.data()?["coins"] as? Int) ?? 0
                let newCoins = max(0, currentCoins - amount) // Don't go below 0

                print("Loser's coins: \(currentCoins) → \(newCoins) (-\(amount))")

                database.collection("users").document(loserId).updateData([
                    "coins": newCoins
                ]) { error in
                    if let error = error {
                        print("Error updating loser's coins: \(error.localizedDescription)")
                        updateError = error
                    } else {
                        print("Loser's coins updated")
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                Task { @MainActor in
                    if let error = updateError {
                        print("Failed to update coins: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        print("Bet completed with payout successfully!")


                        if let currentUserId = Auth.auth().currentUser?.uid {
                            if currentUserId == winnerId {

                                self.userCoins += amount
                                print("Local coins updated: +\(amount) → \(self.userCoins)")
                            } else if currentUserId == loserId {
                                // Current user lost
                                self.userCoins = max(0, self.userCoins - amount)
                                print("Local coins updated: -\(amount) → \(self.userCoins)")
                            }
                        }

                        self.fetchUserCoins()
                        completion(.success(()))
                    }
                }
            }
        }
    }

    // MARK: - Delete Bet

    func deleteBet(betId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("bets").document(betId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - User Search

    func searchUsers(query: String, completion: @escaping ([AppUser]) -> Void) {
        guard !query.isEmpty else {
            completion([])
            return
        }

        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: query)
            .whereField("username", isLessThanOrEqualTo: query + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error searching users: \(error)")
                    completion([])
                    return
                }

                let users = querySnapshot?.documents.compactMap { document -> AppUser? in
                    guard let username = document.data()["username"] as? String,
                          let email = document.data()["email"] as? String,
                          document.documentID != currentUserId else {
                        return nil
                    }
                    return AppUser(id: document.documentID, username: username, email: email)
                } ?? []

                completion(users)
            }
    }

    func getUser(userId: String, completion: @escaping (AppUser?) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error fetching user: \(error)")
                completion(nil)
                return
            }

            guard let document = document,
                  document.exists,
                  let username = document.data()?["username"] as? String,
                  let email = document.data()?["email"] as? String else {
                completion(nil)
                return
            }

            completion(AppUser(id: userId, username: username, email: email))
        }
    }

    func fetchAllUsers(completion: @escaping ([AppUser]) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        db.collection("users")
            .limit(to: 50)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching users: \(error)")
                    completion([])
                    return
                }

                let users = querySnapshot?.documents.compactMap { document -> AppUser? in
                    guard let username = document.data()["username"] as? String,
                          let email = document.data()["email"] as? String,
                          document.documentID != currentUserId else {
                        return nil
                    }
                    return AppUser(id: document.documentID, username: username, email: email)
                } ?? []

                completion(users)
            }
    }

    // MARK: - Coin Management

    func fetchUserCoins() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(currentUserId).getDocument { [weak self] document, error in
            guard let self = self else { return }

            Task { @MainActor in
                if let coins = document?.data()?["coins"] as? Int {
                    self.userCoins = coins
                }

                self.checkDailyCoinStatus()
            }
        }
    }

    func checkDailyCoinStatus() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(currentUserId).getDocument { [weak self] document, error in
            guard let self = self else { return }

            let now = Date()
            let lastClaim = (document?.data()?["lastCoinClaim"] as? Timestamp)?.dateValue()

            Task { @MainActor in
                if let lastClaim = lastClaim {
                    let timeInterval = now.timeIntervalSince(lastClaim)
                    let hoursSinceLastClaim = timeInterval / 3600

                    if hoursSinceLastClaim >= 24 {
                        self.canClaimDailyCoins = true
                        self.timeUntilNextClaim = "Ready to claim!"
                    } else {
                        self.canClaimDailyCoins = false
                        let remainingSeconds = (24 * 3600) - timeInterval
                        self.timeUntilNextClaim = self.formatTimeRemaining(seconds: remainingSeconds)
                    }
                } else {
                    self.canClaimDailyCoins = true
                    self.timeUntilNextClaim = "Ready to claim!"
                }
            }
        }
    }

    func claimDailyCoins(completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        guard canClaimDailyCoins else {
            completion(false)
            return
        }

        let database = db

        database.collection("users").document(currentUserId).getDocument { [weak self] document, error in
            guard let self = self else {
                completion(false)
                return
            }

            if let error = error {
                completion(false)
                return
            }

            let currentCoins = (document?.data()?["coins"] as? Int) ?? 0
            let newCoins = currentCoins + 1000

            database.collection("users").document(currentUserId).updateData([
                "coins": newCoins,
                "lastCoinClaim": Timestamp(date: Date())
            ]) { error in
                Task { @MainActor in
                    if error == nil {
                        self.userCoins = newCoins
                        self.canClaimDailyCoins = false
                        self.checkDailyCoinStatus()
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
        }
    }

    private func formatTimeRemaining(seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    /// Update user's coin balance (deduct for bets, etc.)
    func updateCoins(amount: Int, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let database = db

        database.collection("users").document(currentUserId).updateData([
            "coins": amount
        ]) { [weak self] error in
            Task { @MainActor in
                if error == nil {
                    self?.userCoins = amount
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }

    // MARK: - Friends Management

    func sendFriendRequest(toUserId: String, completion: @escaping (Bool) -> Void) {
        print("sendFriendRequest called for user: \(toUserId)")

        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("No current user")
            completion(false)
            return
        }

        print("🔵 Current user: \(currentUserId)")

        let database = db

        database.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: currentUserId)
            .whereField("toUserId", isEqualTo: toUserId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking existing requests: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                if let documents = snapshot?.documents, !documents.isEmpty {
                    print("Request already exists")
                    completion(false)
                    return
                }

                print("Creating new friend request...")

                let requestData: [String: Any] = [
                    "fromUserId": currentUserId,
                    "toUserId": toUserId,
                    "status": "pending",
                    "createdAt": Timestamp(date: Date())
                ]

                database.collection("friendRequests").addDocument(data: requestData) { error in
                    if let error = error {
                        print("Error creating request: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Friend request created successfully")
                        completion(true)
                    }
                }
            }
    }

    func removeFriend(friendId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let database = db

        database.collection("users").document(currentUserId).getDocument { [weak self] document, error in
            guard let self = self else { return }

            var friends = (document?.data()?["friends"] as? [String]) ?? []
            friends.removeAll { $0 == friendId }

            database.collection("users").document(currentUserId).updateData([
                "friends": friends
            ]) { error in
                Task { @MainActor in
                    if error == nil {
                        self.fetchFriends()
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
        }
    }

    func fetchFriends() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(currentUserId).addSnapshotListener { [weak self] document, error in
            guard let self = self else { return }

            let friendIds = (document?.data()?["friends"] as? [String]) ?? []

            if friendIds.isEmpty {
                Task { @MainActor in
                    self.friendsList = []
                }
                return
            }

            var fetchedFriends: [AppUser] = []
            let group = DispatchGroup()
            let db = self.db

            for friendId in friendIds {
                group.enter()
                db.collection("users").document(friendId).getDocument { document, error in
                    if let document = document, document.exists,
                       let username = document.data()?["username"] as? String,
                       let email = document.data()?["email"] as? String {
                        fetchedFriends.append(AppUser(id: friendId, username: username, email: email))
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                Task { @MainActor in
                    self.friendsList = fetchedFriends
                }
            }
        }
    }

    func isFriend(userId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        db.collection("users").document(currentUserId).getDocument { document, error in
            let friends = (document?.data()?["friends"] as? [String]) ?? []
            completion(friends.contains(userId))
        }
    }

    // MARK: - Friend Requests

    func fetchFriendRequests() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        db.collection("friendRequests")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }

                var requests: [FriendRequest] = []
                let group = DispatchGroup()

                for document in documents {
                    if let fromUserId = document.data()["fromUserId"] as? String,
                       let createdAt = document.data()["createdAt"] as? Timestamp {

                        group.enter()
                        self.getUser(userId: fromUserId) { user in
                            if let user = user {
                                let request = FriendRequest(
                                    id: document.documentID,
                                    fromUser: user,
                                    createdAt: createdAt.dateValue()
                                )
                                requests.append(request)
                            }
                            group.leave()
                        }
                    }
                }

                group.notify(queue: .main) {
                    Task { @MainActor in
                        self.friendRequests = requests.sorted { $0.createdAt > $1.createdAt }
                    }
                }
            }
    }


    func acceptFriendRequest(requestId: String, fromUserId: String, completion: @escaping (Bool) -> Void) {
        print("Accepting friend request: \(requestId) from \(fromUserId)")

        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("No current user")
            completion(false)
            return
        }

        print("Current user: \(currentUserId)")

        let database = db

        let group = DispatchGroup()
        var success = true

        group.enter()
        database.collection("users").document(currentUserId).getDocument { [weak self] document, error in
            guard let self = self else {
                group.leave()
                return
            }

            if let error = error {
                print("Error fetching current user: \(error.localizedDescription)")
                success = false
                group.leave()
                return
            }

            var friends = (document?.data()?["friends"] as? [String]) ?? []
            print("Current user's friends before: \(friends)")

            if !friends.contains(fromUserId) {
                friends.append(fromUserId)
            }

            print("Current user's friends after: \(friends)")

            database.collection("users").document(currentUserId).updateData([
                "friends": friends
            ]) { error in
                if let error = error {
                    print("Error updating current user's friends: \(error.localizedDescription)")
                    success = false
                } else {
                    print("Updated current user's friends")
                }
                group.leave()
            }
        }

        group.enter()
        database.collection("users").document(fromUserId).getDocument { [weak self] document, error in
            guard let self = self else {
                group.leave()
                return
            }

            if let error = error {
                print("Error fetching friend user: \(error.localizedDescription)")
                success = false
                group.leave()
                return
            }

            var friends = (document?.data()?["friends"] as? [String]) ?? []
            print("Friend's friends before: \(friends)")

            if !friends.contains(currentUserId) {
                friends.append(currentUserId)
            }

            print("Friend's friends after: \(friends)")

            database.collection("users").document(fromUserId).updateData([
                "friends": friends
            ]) { error in
                if let error = error {
                    print("Error updating friend's friends: \(error.localizedDescription)")
                    success = false
                } else {
                    print("Updated friend's friends")
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            print("Both users updated, now updating request status...")

            database.collection("friendRequests").document(requestId).updateData([
                "status": "accepted"
            ]) { error in
                Task { @MainActor in
                    if let error = error {
                        print("Error updating request status: \(error.localizedDescription)")
                        completion(false)
                    } else if !success {
                        print("Failed to update one or both users")
                        completion(false)
                    } else {
                        print("Friend request accepted successfully!")
                        self.fetchFriends()
                        self.fetchFriendRequests()
                        completion(true)
                    }
                }
            }
        }
    }

    func declineFriendRequest(requestId: String, completion: @escaping (Bool) -> Void) {
        let database = db

        database.collection("friendRequests").document(requestId).updateData([
            "status": "declined"
        ]) { [weak self] error in
            Task { @MainActor in
                if error == nil {
                    self?.fetchFriendRequests()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }

    func hasPendingRequest(userId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        db.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: currentUserId)
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                completion(!(snapshot?.documents.isEmpty ?? true))
            }
    }
}


struct AppUser: Identifiable, Codable, Sendable {
    var id: String
    var username: String
    var email: String
}


struct FriendRequest: Identifiable {
    var id: String
    var fromUser: AppUser
    var createdAt: Date
}

