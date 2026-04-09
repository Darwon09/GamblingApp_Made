//
//  CreateBetView.swift
//  GamblingApp
//
//  Created by Darren Ich on 12/6/25.
//

import SwiftUI

struct CreateBetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var betManager = BetManager.shared
    @State private var selectedUser: AppUser? = nil
    @State private var betTitle: String = ""
    @State private var betDescription: String = ""
    @State private var amount: String = ""
    @State private var showFriendSelect: Bool = false
    @State private var isCreating: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false

    let primaryGreen = Color(red: 41/255, green: 87/255, blue: 50/255)
    let lightGray = Color(red: 242/255, green: 242/255, blue: 247/255)

    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bet With")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(primaryGreen)

                            Button(action: {
                                showFriendSelect = true
                            }) {
                                HStack {
                                    if let user = selectedUser {
                                        Text(user.username)
                                            .foregroundColor(.black)
                                    } else {
                                        Text("Select a friend")
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(primaryGreen)
                                }
                                .padding()
                                .background(lightGray)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(primaryGreen, lineWidth: 2)
                                )
                                .cornerRadius(25)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 20)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("What's the bet?")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(primaryGreen)

                            TextField("e.g., Lakers will win tonight", text: $betTitle)
                                .textInputAutocapitalization(.sentences)
                                .foregroundColor(.black)
                                .padding()
                                .background(lightGray)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(primaryGreen, lineWidth: 2)
                                )
                                .cornerRadius(25)
                        }
                        .padding(.horizontal, 40)


                        VStack(alignment: .leading, spacing: 8) {
                            Text("Details (Optional)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(primaryGreen)

                            TextField("Add more details about the bet", text: $betDescription)
                                .textInputAutocapitalization(.sentences)
                                .foregroundColor(.black)
                                .padding()
                                .background(lightGray)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(primaryGreen, lineWidth: 2)
                                )
                                .cornerRadius(25)
                        }
                        .padding(.horizontal, 40)

                        // Amount
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount ($)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(primaryGreen)

                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .foregroundColor(.black)
                                .padding()
                                .background(lightGray)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(primaryGreen, lineWidth: 2)
                                )
                                .cornerRadius(25)
                        }
                        .padding(.horizontal, 40)


                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        Button(action: {
                            createBet()
                        }) {
                            HStack {
                                if isCreating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isCreating ? "Creating..." : "Create Bet")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(primaryGreen)
                            .cornerRadius(25)
                        }
                        .disabled(isCreating)
                        .opacity(isCreating ? 0.7 : 1.0)
                        .padding(.horizontal, 40)
                        .padding(.top, 10)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Create Bet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(primaryGreen)
                }
            }
            .sheet(isPresented: $showFriendSelect) {
                FriendSelectorView(selectedUser: $selectedUser)
            }
            .onAppear {
                betManager.fetchFriends()
            }
            .alert("Bet Created!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your bet has been sent successfully!")
            }
        }
    }

    func createBet() {
        errorMessage = ""


        guard let user = selectedUser else {
            errorMessage = "Please select a friend"
            return
        }

        guard !betTitle.isEmpty else {
            errorMessage = "Please enter what the bet is about"
            return
        }

        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }

        isCreating = true

        BetManager.shared.createBet(
            participantId: user.id,
            participantUsername: user.username,
            title: betTitle,
            description: betDescription,
            amount: amountValue
        ) { result in
            isCreating = false

            switch result {
            case .success:
                showSuccess = true
            case .failure(let error):
                errorMessage = "Failed to create bet: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    CreateBetView()
}
