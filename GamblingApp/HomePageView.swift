//
//  HomePageView.swift
//  GamblingApp
//
//  Created by Darren Ich on 12/5/25.
//

import SwiftUI
import FirebaseAuth

struct HomePageView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var betManager = BetManager.shared
    @State private var showCreateBet: Bool = false
    @State private var showFriendSearch: Bool = false
    @State private var showFriendsList: Bool = false
    @State private var showFriendRequests: Bool = false
    @State private var showSidebar: Bool = false
    @State private var selectedFriend: AppUser? = nil
    @State private var selectedBet: Bet? = nil
    @State private var showBetDetail: Bool = false
    @State private var timer: Timer?
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    let primaryGreen = Color(red: 41/255, green: 87/255, blue: 50/255)
    let lightGray = Color(red: 242/255, green: 242/255, blue: 247/255)

    var pendingBets: [Bet] {
        betManager.userBets.filter { $0.isPending }
    }

    var activeBets: [Bet] {
        betManager.userBets.filter { $0.isActive }
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header with menu button and coins
                    HStack {
                        Button(action: {
                            showSidebar = true
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundColor(primaryGreen)
                        }

                        Button(action: {
                            showFriendSearch = true
                        }) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(primaryGreen)
                        }
                        .padding(.leading, 10)

                        Spacer()

                        // Coin Balance & Claim Button
                        HStack(spacing: 10) {
                            // Current Balance
                            HStack(spacing: 6) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(red: 218/255, green: 165/255, blue: 32/255))
                                Text("\(betManager.userCoins)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(lightGray)
                            .cornerRadius(20)

                            // Claim Button
                            Button(action: {
                                claimDailyCoins()
                            }) {
                                VStack(spacing: 2) {
                                    if betManager.canClaimDailyCoins {
                                        Text("Claim")
                                            .font(.system(size: 12, weight: .bold))
                                        Text("1000")
                                            .font(.system(size: 10, weight: .semibold))
                                    } else {
                                        Text(betManager.timeUntilNextClaim)
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(betManager.canClaimDailyCoins ? primaryGreen : Color.gray)
                                .cornerRadius(15)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                    // Title
                    HStack {
                        Text("My Bets")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                    // Pending Bets Section
                    if !pendingBets.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Pending (\(pendingBets.count))")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(primaryGreen)
                                .padding(.horizontal, 20)

                            ForEach(pendingBets) { bet in
                                BetCard(bet: bet, currentUserId: getCurrentUserId())
                                    .padding(.horizontal, 20)
                                    .onTapGesture {
                                        selectedBet = bet
                                        showBetDetail = true
                                    }
                            }
                        }
                        .padding(.bottom, 20)
                    }

                    // Active Bets Section
                    if !activeBets.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Active (\(activeBets.count))")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(primaryGreen)
                                .padding(.horizontal, 20)

                            ForEach(activeBets) { bet in
                                BetCard(bet: bet, currentUserId: getCurrentUserId())
                                    .padding(.horizontal, 20)
                                    .onTapGesture {
                                        selectedBet = bet
                                        showBetDetail = true
                                    }
                            }
                        }
                        .padding(.bottom, 20)
                    }

                    // Empty State
                    if pendingBets.isEmpty && activeBets.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "tray")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No Current Bets")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.gray)
                            Text("Tap the button below to create your first bet!")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 80)
                        .padding(.horizontal, 40)
                    }

                    Spacer(minLength: 100)
                }
            }

            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showCreateBet = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                            Text("Create Bet")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(primaryGreen)
                        .cornerRadius(30)
                        .shadow(color: primaryGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 30)
                }
            }

            // Sidebar Overlay
            if showSidebar {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showSidebar = false
                    }

                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        // Sidebar Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Menu")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)

                            if let user = Auth.auth().currentUser {
                                Text(user.email ?? "")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        .padding(.bottom, 30)

                        Divider()

                        // Menu Items
                        VStack(alignment: .leading, spacing: 0) {
                            // Friend Requests Button
                            Button(action: {
                                showSidebar = false
                                showFriendRequests = true
                            }) {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 20))
                                        .foregroundColor(primaryGreen)
                                    Text("Friend Requests")
                                        .font(.system(size: 18))
                                        .foregroundColor(.black)
                                    Spacer()
                                    if !betManager.friendRequests.isEmpty {
                                        Text("\(betManager.friendRequests.count)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.red)
                                            .cornerRadius(10)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }

                            Divider()

                            // Friends Button
                            Button(action: {
                                showSidebar = false
                                showFriendsList = true
                            }) {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(primaryGreen)
                                    Text("Friends")
                                        .font(.system(size: 18))
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }

                            Divider()

                            // Sign Out Button
                            Button(action: {
                                signOut()
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 20))
                                        .foregroundColor(primaryGreen)
                                    Text("Sign Out")
                                        .font(.system(size: 18))
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                        }

                        Spacer()
                    }
                    .frame(width: 280)
                    .background(Color.white)
                    .transition(.move(edge: .leading))

                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showCreateBet) {
            CreateBetView()
        }
        .sheet(isPresented: $showFriendSearch) {
            UserSearchView(selectedUser: $selectedFriend)
        }
        .sheet(isPresented: $showFriendsList) {
            FriendsView()
        }
        .sheet(isPresented: $showFriendRequests) {
            FriendRequestsView()
        }
        .sheet(isPresented: $showBetDetail) {
            if let bet = selectedBet {
                BetDetailView(bet: bet)
            }
        }
        .alert("Coin Claim", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            betManager.fetchUserBets()
            betManager.fetchUserCoins()
            betManager.fetchFriends()
            betManager.fetchFriendRequests()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    func getCurrentUserId() -> String {
        return Auth.auth().currentUser?.uid ?? ""
    }

    func claimDailyCoins() {
        betManager.claimDailyCoins { success in
            if success {
                alertMessage = "Successfully claimed 1000 coins!\nNew balance: \(betManager.userCoins)"
                showAlert = true
            }
        }
    }

    func startTimer() {
        // Update the timer every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                betManager.checkDailyCoinStatus()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            dismiss()
        } catch {
            alertMessage = "Failed to sign out. Please try again."
            showAlert = true
        }
    }
}

// MARK: - Bet Card Component

struct BetCard: View {
    let bet: Bet
    let currentUserId: String
    let primaryGreen = Color(red: 41/255, green: 87/255, blue: 50/255)
    let lightGray = Color(red: 242/255, green: 242/255, blue: 247/255)

    var isCreator: Bool {
        bet.creatorId == currentUserId
    }

    var opponentName: String {
        isCreator ? bet.participantUsername : bet.creatorUsername
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
        HStack {
                ZStack {
                    Circle()
                        .fill(primaryGreen.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Text(String(opponentName.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(primaryGreen)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("vs. \(opponentName)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    Text(isCreator ? "You created this bet" : "Bet from \(bet.creatorUsername)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()

                // Amount
                Text("$\(String(format: "%.0f", bet.amount))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primaryGreen)
            }

            Text(bet.title)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .lineLimit(2)

            if !bet.description.isEmpty {
                Text(bet.description)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            HStack {
                Image(systemName: bet.isPending ? "clock" : "checkmark.circle.fill")
                    .font(.system(size: 12))
                Text(bet.status.rawValue.capitalized)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(bet.isPending ? .orange : primaryGreen)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(bet.isPending ? Color.orange.opacity(0.1) : primaryGreen.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(lightGray, lineWidth: 1)
        )
    }
}

#Preview {
    HomePageView()
}

