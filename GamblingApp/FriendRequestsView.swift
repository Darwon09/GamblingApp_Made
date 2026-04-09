//
//  FriendRequestsView.swift
//  GamblingApp
//
//  Created by Darren Ich on 12/10/25.
//

import SwiftUI

struct FriendRequestsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var betManager = BetManager.shared

    let primaryGreen = Color(red: 41/255, green: 87/255, blue: 50/255)
    let lightGray = Color(red: 242/255, green: 242/255, blue: 247/255)

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if betManager.friendRequests.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Friend Requests")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                        Text("When someone sends you a friend request, it will appear here!")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 80)
                    .padding(.horizontal, 40)
                } else {
                    List {
                        ForEach(betManager.friendRequests) { request in
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(primaryGreen.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    Text(String(request.fromUser.username.prefix(1)).uppercased())
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(primaryGreen)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(request.fromUser.username)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.black)
                                    Text(request.fromUser.email)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                HStack(spacing: 8) {
                                    Button(action: {
                                        betManager.acceptFriendRequest(requestId: request.id, fromUserId: request.fromUser.id) { _ in }
                                    }) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 36, height: 36)
                                            .background(primaryGreen)
                                            .cornerRadius(8)
                                    }

                                    Button(action: {
                                        betManager.declineFriendRequest(requestId: request.id) { _ in }
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 36, height: 36)
                                            .background(Color.red)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Friend Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(primaryGreen)
                }
            }
        }
        .onAppear {
            betManager.fetchFriendRequests()
        }
    }
}

#Preview {
    FriendRequestsView()
}
