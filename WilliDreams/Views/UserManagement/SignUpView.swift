//
//  SignUpView.swift
//  WilliStudy
//
//  Created by William Gallegos on 2/24/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import AuthenticationServices
import WilliKit

struct SignUpView: View {
    @StateObject private var authManager = AuthManager()
    @AppStorage("loginStatus") private var isLoggedIn = false
    
    private let authDelegateHandler = AuthorizationControllerDelegateHandler()
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var emailEntry = ""
    @State private var passwordEntry = ""
    @State private var username = ""
    
    @State private var agreeToTOS = true
    
    var body: some View {
        ZStack {
#if !os(watchOS)
            ContainerRelativeShape()
                .foregroundStyle(Color("BackgroundColor"))
                .ignoresSafeArea()
#endif
            //VStack {
                VStack {
                    Image("LaunchIcon")
                        .resizable()
                        .frame(width: 30, height: 30)
                    Text(NSLocalizedString("Create an account!", comment: ""))
                        .font(.title)
                        .bold()
                    Divider()
                    Group {
                        TextField("Email", text: $emailEntry)
                            .textContentType(.emailAddress)
                        TextField("Username", text: $username)
                        SecureField("Password", text: $passwordEntry)
                            .textContentType(.newPassword)
                    }
                    .textFieldStyle(WillTextFieldStyle())
                    .layoutPriority(2)
                    
                    Button(action: {
                        Task {
                            await authManager.signUp(email: emailEntry, password: passwordEntry, username: username)
                            if isLoggedIn == true {
                                dismiss()
                            }
                        }
                    }) {
                        Text("Sign up")
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
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
                    .disabled(username == "" || passwordEntry == "" || emailEntry == "")
                    .opacity(username == "" || passwordEntry == "" || emailEntry == "" ? 0.4 : 1)
                    
                    Link(destination: URL(string: "https://www.williamgallegos.net/williapps-terms-of-service")!, label: {
                        Text("By signing up, you agree to the WilliApps Terms of Service")
                    })
                    .withHoverEffect()
                    
                    SignInWithAppleButton(.signUp) { request in
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
                //.layoutPriority(1)
            //}
            
            LoadingOverlayView(isShowing: $authManager.isLoading)
        }
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
    SignUpView()
}
