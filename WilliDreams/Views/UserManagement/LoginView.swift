//
//  LoginView.swift
//  WilliStudy
//
//  Created by William Gallegos on 2/24/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import Security
import AuthenticationServices
import CryptoKit
import WilliKit

struct LoginView: View {
    @StateObject private var authManager = AuthManager()
    @AppStorage("loginStatus") private var isLoggedIn = false
    
    private let authDelegateHandler = AuthorizationControllerDelegateHandler()
    
    @State private var emailEntry = ""
    @State private var passwordEntry = ""
    @State private var username = ""
    
    @State private var forgotPasswordShown = false
    @State private var forgotPasswordEmailEntry = ""
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
#if !os(watchOS)
            ContainerRelativeShape()
                .foregroundStyle(Color("BackgroundColor"))
                .ignoresSafeArea()
#endif
            VStack {
                Image("LaunchIcon")
                    .resizable()
                    .frame(width: 30, height: 30)
                Text("Welcome Back!")
                    .font(.title)
                    .bold()
                Text(NSLocalizedString("Sign in to your account below.", comment: ""))
                Divider()
                VStack {
                    Group {
                        TextField("Email", text: $emailEntry)
                            .textContentType(.emailAddress)
                        SecureField("Password", text: $passwordEntry)
                            .textContentType(.password)
                    }
                    .textFieldStyle(WillTextFieldStyle())
                    
                    
                    Button(action: {
                        Task {
                            await authManager.loginUser(email: emailEntry, password: passwordEntry)
                            if isLoggedIn == true {
                                dismiss()
                            }
                        }
                    }) {
                        HStack {
                            Text("Sign In")
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .bold()
#if !os(visionOS)
                    .buttonStyle(.borderless)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(20)
                    .withHoverEffect()
#else
                    .font(.largeTitle)
#endif
                    .padding(.top)
                }
                Button("Forgot Password?", action: {
                    forgotPasswordShown = true
                })
                    .padding()
                Divider()
                
                SignInWithAppleButton(.signIn) { request in
                    let nonce = authManager.randomNonceString()
                    authManager.nonce = nonce
                    request.requestedScopes = [.email, .fullName]
                    request.nonce = authManager.sha256(nonce)
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        Task {
                            await authManager.signInWithApple(authorization: authorization)
                            if isLoggedIn == true {
                                dismiss()
                            }
                        }
                    case .failure(let error):
                        Task {
                            await authManager.showError(message: error.localizedDescription)
                        }
                    }
                }
                .frame(height: 45)
                .cornerRadius(20)
            }
            .williBackground()
            .padding(.horizontal)
            
            LoadingOverlayView(isShowing: $authManager.isLoading)
        }
        .alert("Forgot Password?", isPresented: $forgotPasswordShown, actions: {
            TextField("Email", text: $forgotPasswordEmailEntry)
            Button("Send Forgot Password") {
                Task {
                    await authManager.resetPassword(email: forgotPasswordEmailEntry)
                }
            }
            Button("Cancel", role: .cancel) {forgotPasswordShown = false}
        }, message: {Text("Please enter your email so we can send you a link to reset your password.")})
        .alert(authManager.errorMessage, isPresented: $authManager.showError, actions: {})
        .alert("Create Username", isPresented: $authManager.isSignInWithAppleUsernamePromptEnabled) {
            TextField("Choose Username", text: $username)
            Button("Submit") {
                Task { await authManager.handleUsernamePrompt(username: username) }
            }
        }
    }
}

#Preview {
    LoginView()
}
