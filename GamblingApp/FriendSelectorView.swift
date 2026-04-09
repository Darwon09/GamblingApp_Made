//
//  FriendSelectorView.swift
//  GamblingApp
//
//  Created by Darren Ich on 12/10/25.
//

import SwiftUI

struct FriendSelectorView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedUser: AppUser?
    @StateObject private var betManager = BetManager.shared

    let primaryGreen = Color(red: 41/255, green: 87/255, blue: 50/255)
    let lightGray = Color(red: 242/255, green: 242/255, blue: 247/255)

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if betManager.friendsList.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Friends Yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                        Text("Add friends first before creating bets!")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 80)
                    .padding(.horizontal, 40)
                } else {
                    List(betManager.friendsList) { friend in
                        Button(action: {
                            selectedUser = friend
                            dismiss()
                        }) {
                            HStack {
                                // Avatar
                                ZStack {
                                    Circle()
                                        .fill(primaryGreen.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    Text(String(friend.username.prefix(1)).uppercased())
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(primaryGreen)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(friend.username)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.black)
                                    Text(friend.email)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        }
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
            betManager.fetchFriends()
        }
    }
}

#Preview {
    FriendSelectorView(selectedUser: .constant(nil))
}
