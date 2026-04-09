//
//  loginview.swift
//  GamblingApp
//
//  Created by Darren Ich on 12/5/25.
//

import SwiftUI
import FirebaseAuth

struct loginview: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var showSignUp: Bool = false

    let primaryGreen = Color(red: 41/255, green: 87/255, blue: 50/255)
    let lightGray = Color(red: 242/255, green: 242/255, blue: 247/255)

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 60)

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
                    .padding(.bottom, 20)

                    Text("Welcome to BetAny")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)

                    Text("The new way to make custom\nbets with friends")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
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
                        Text("Password")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(primaryGreen)

                        SecureField("Enter password", text: $password)
                            .padding()
                            .background(lightGray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(primaryGreen, lineWidth: 2)
                            )
                            .cornerRadius(25)
                    }
                    .padding(.horizontal, 40)

                    HStack {
                        Spacer()
                        Button(action: {
                        }) {
                            Text("Forgot Password?")
                                .font(.system(size: 14))
                                .foregroundColor(primaryGreen)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, -10)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Button(action: {
                        handleLogin()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Logging in..." : "Login to BetAny")
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

                    HStack {
                        Text("Don't have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        Button(action: {
                            showSignUp = true
                        }) {
                            Text("Sign Up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(primaryGreen)
                        }
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .fullScreenCover(isPresented: $isLoggedIn) {
            HomePageView()
        }
    }

    func handleLogin() {
        errorMessage = ""

        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }

        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return
        }

        isLoading = true

         Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
             isLoading = false
        
             if let error = error {
                 errorMessage = getErrorMessage(for: error)
                 return
             }
             if let user = authResult?.user {
                 print("Login successful! User ID: \(user.uid)")
                 isLoggedIn = true
             }
         }
    }

    func getErrorMessage(for error: Error) -> String {
         let nsError = error as NSError
        
         switch nsError.code {
         case AuthErrorCode.wrongPassword.rawValue:
             return "Incorrect password. Please try again."
         case AuthErrorCode.userNotFound.rawValue:
             return "No account found with this email."
         case AuthErrorCode.invalidEmail.rawValue:
             return "Please enter a valid email address."
         case AuthErrorCode.networkError.rawValue:
             return "Network error. Please check your connection."
         case AuthErrorCode.tooManyRequests.rawValue:
             return "Too many attempts. Please try again later."
         default:
             return "Login failed. Please try again."
         }
    }
}

#Preview {
    loginview()
}
