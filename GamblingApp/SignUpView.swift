//
//  SignUpView.swift
//  GamblingApp
//
//  Created by Darren Ich on 12/5/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var isSignedUp: Bool = false
    @Environment(\.dismiss) var dismiss

    let primaryGreen = Color(red: 41/255, green: 87/255, blue: 50/255)
    let lightGray = Color(red: 242/255, green: 242/255, blue: 247/255)

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 20)

                    ZStack {
                        ZStack {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 80))
                                .foregroundColor(primaryGreen)

                            HStack(spacing: 2) {
                                Image(systemName: "dollarsign")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(red: 218/255, green: 165/255, blue: 32/255))

                                Image(systemName: "dice.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            .offset(y: -5)
                        }

                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Back")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(primaryGreen)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 20)

                    Text("Welcome to BetAny")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40)

                    Text("The new way to make custom\nbets with friends")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(primaryGreen)

                        TextField("Input email address", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
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
                        Text("Username")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(primaryGreen)

                        TextField("Public Username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
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
                        Text("Password")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(primaryGreen)

                        SecureField("Enter password", text: $password)
                            .textContentType(.newPassword)
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
                        Text("Confirm Password")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(primaryGreen)

                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
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
                        handleSignUp()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Creating Account..." : "Join BetAny")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(primaryGreen)
                        .cornerRadius(25)
                    }
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.7 : 1.0)
                    .padding(.horizontal, 40)
                    .padding(.top, 10)

                    Spacer()
                }
            }
        }
        .fullScreenCover(isPresented: $isSignedUp) {
            HomePageView()
        }
    }

    func handleSignUp() {
        errorMessage = ""

        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }

        guard !username.isEmpty else {
            errorMessage = "Please enter a username"
            return
        }

        guard !password.isEmpty else {
            errorMessage = "Please enter a password"
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        isLoading = true


         Auth.auth().createUser(withEmail: email, password: password) { [self] authResult, error in
             isLoading = false

             if let error = error {
                 errorMessage = getErrorMessage(for: error)
                 return
             }

             if let user = authResult?.user {
                 print("Sign up successful! User ID: \(user.uid)")

                 let db = Firestore.firestore()
                 db.collection("users").document(user.uid).setData([
                     "username": username,
                     "email": email,
                     "coins": 0,
                     "createdAt": Timestamp(date: Date())
                 ]) { error in
                     if let error = error {
                         print("Error saving user data: \(error.localizedDescription)")
                         errorMessage = "Account created but failed to save profile"
                     } else {
                         print("User data saved successfully!")
                         isSignedUp = true
                     }
                 }
             }
         }

    }

    func getErrorMessage(for error: Error) -> String {
         let nsError = error as NSError
        
         switch nsError.code {
         case AuthErrorCode.emailAlreadyInUse.rawValue:
             return "This email is already registered."
         case AuthErrorCode.invalidEmail.rawValue:
             return "Please enter a valid email address."
         case AuthErrorCode.weakPassword.rawValue:
             return "Password is too weak. Use at least 6 characters."
         case AuthErrorCode.networkError.rawValue:
             return "Network error. Please check your connection."
         default:
             return "Sign up failed. Please try again."
         }
    }
}

#Preview {
    SignUpView()
}

