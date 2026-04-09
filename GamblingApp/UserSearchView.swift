//
//  UserSearchView.swift
//  GamblingApp
//
//  Created by Darren Ich on 12/5/25.
//

import SwiftUI

struct UserSearchView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedUser: AppUser?
    @State private var searchQuery: String = ""
    @State private var searchResults: [AppUser] = []
    @State private var allUsers: [AppUser] = []
    @State private var isSearching: Bool = false
    @State private var friendStatus: [String: Bool] = [:]
    @State private var pendingRequests: [String: Bool] = [:]
    @StateObject private var betManager = BetManager.shared

    let primaryGreen = Color(red: 41/255, green: 87/255, blue: 50/255)
    let lightGray = Color(red: 242/255, green: 242/255, blue: 247/255)

    var displayedUsers: [AppUser] {
        searchQuery.isEmpty ? [] : searchResults
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by username", text: $searchQuery)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundColor(.black)
                        .onChange(of: searchQuery) { oldValue, newValue in
                            searchUsers(query: newValue)
                        }
                    if !searchQuery.isEmpty {
                        Button(action: {
                            searchQuery = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(lightGray)
                .cornerRadius(10)
                .padding()

                // Results List
                if isSearching {
                    ProgressView()
                        .padding()
                } else if displayedUsers.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text(searchQuery.isEmpty ? "Search for users by username" : "No users found")
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                } else {
                    List(displayedUsers) { user in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(primaryGreen.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                Text(String(user.username.prefix(1)).uppercased())
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(primaryGreen)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.username)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                Text(user.email)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            if friendStatus[user.id] == true {
                                Text("Friends")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            } else if pendingRequests[user.id] == true {
                                Text("Requested")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.orange)
                            } else {
                                Button(action: {
                                    sendFriendRequest(user: user)
                                }) {
                                    Text("Add Friend")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(primaryGreen)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(primaryGreen.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listStyle(PlainListStyle())
                }

                Spacer()
            }
            .navigationTitle("Select Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(primaryGreen)
                }
            }
        }
        .onAppear {
            loadAllUsers()
        }
    }

    func searchUsers(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        BetManager.shared.searchUsers(query: query) { users in
            isSearching = false
            searchResults = users
            checkFriendStatus(for: users)
        }
    }

    func loadAllUsers() {
        isSearching = true
        BetManager.shared.fetchAllUsers { users in
            isSearching = false
            allUsers = users
        }
    }

    func checkFriendStatus(for users: [AppUser]) {
        for user in users {
            betManager.isFriend(userId: user.id) { isFriend in
                friendStatus[user.id] = isFriend
            }
            betManager.hasPendingRequest(userId: user.id) { hasPending in
                pendingRequests[user.id] = hasPending
            }
        }
    }

    func sendFriendRequest(user: AppUser) {
        print("Sending friend request to: \(user.username)")
        betManager.sendFriendRequest(toUserId: user.id) { success in
            print(success ? "Friend request sent!" : "Friend request failed")
            if success {
                pendingRequests[user.id] = true
            }
        }
    }
}

#Preview {
    UserSearchView(selectedUser: .constant(nil))
}
