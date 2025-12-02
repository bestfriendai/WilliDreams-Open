//
//  FirstStartup.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/28/24.
//

import SwiftUI
import AuthenticationServices

struct FirstStartup_LEGACY: View {
    @StateObject private var authManager = AuthManager()
    
    @Binding var isGuest: Bool
    @State private var confirmGuest = false
    
    @State private var username: String = ""
    
    var body: some View {
        if isGuest == false {
            NavigationStack {
                ZStack {
#if !os(watchOS)
                    ContainerRelativeShape()
                        .foregroundStyle(.window)
                        .ignoresSafeArea()
#endif
                    VStack {
                        Spacer()
                        Image("LaunchIcon")
                            .resizable()
                            .frame(width: 100, height: 100)
                        Text("Welcome to WilliDreams!")
                            .font(.title)
                            .bold()
                        Text("The easiest way to track and share your dreams with your friends")
                        Spacer()
                        
                        VStack {
                            #if os(macOS)
                            
                            #else
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
                                    }
                                case .failure(let error):
                                    Task {
                                        await authManager.showError(message: error.localizedDescription)
                                    }
                                }
                            }
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(20)
                            .withHoverEffect()
                            #endif
                            
                            NavigationLink(destination: SignUpView()) {
                                #if os(macOS)
                                Text("Sign up")
                                    .bold()
                                    .frame(height: 50)
                                    .frame(maxWidth: .infinity)
                                #else
                                Text("Sign up With Email")
                                    .bold()
                                    .frame(height: 50)
                                    .frame(maxWidth: .infinity)
                                #endif
                            }
                            .buttonStyle(.borderless)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .cornerRadius(20)
                            .withHoverEffect()
    #if !os(visionOS)
                            //.buttonStyle(WillButtonStyle())
    #endif
                            
                            NavigationLink(destination: LoginView()) {
                                Text("Sign in")
                                    .bold()
                                    .frame(height: 50)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderless)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .cornerRadius(20)
                            .withHoverEffect()
    #if !os(visionOS)
                            //.buttonStyle(WillButtonStyle())
    #endif
                            Button("Continue as guest", action: {
                                confirmGuest = true
                            })
                            .buttonStyle(.plain)
                            .foregroundStyle(Color("TextColorSet"))
                        }
                        .frame(maxWidth: 500)
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                //.foregroundStyle(.element)
                        }
                        .padding(.horizontal)
                        #if os(macOS)
                        .padding(.bottom)
                        #endif
                    }
                }
                .alert("Are you sure you wish to continue as a guest?", isPresented: $confirmGuest, actions: {
                    Button("Im Sure") { isGuest = true }
                    Button("Cancel", role: .cancel) {}
                }, message: {
                    Text("You will not gain any social features, like sharing your dreams. You will be able to make an account at any time.")
                })
            }
            .alert(authManager.errorMessage, isPresented: $authManager.showError, actions: {})
            .alert("Create Username", isPresented: $authManager.isSignInWithAppleUsernamePromptEnabled) {
                TextField("Choose Username", text: $username)
                Button("Submit") {
                    Task { await authManager.handleUsernamePrompt(username: username) }
                }
            }
        } else {
            ContentView()
        }
    }
}

struct FirstStartup: View {
    @StateObject private var authManager = AuthManager()
    
    @Binding var isGuest: Bool
    @State private var confirmGuest = false
    
    @State private var username: String = ""
    
    @State private var navigationHandler = NavigationHandler.shared
    
    var body: some View {
        NavigationStack(path: $navigationHandler.path.animation(.smooth)) {
            ZStack {
#if !os(watchOS)
                ContainerRelativeShape()
                    .foregroundStyle(Color("BackgroundColor"))
                    .ignoresSafeArea()
#endif
                VStack {
                    Spacer()
                    Image("LaunchIcon")
                        .resizable()
                        .frame(width: 100, height: 100)
                    Text("Welcome to WilliDreams!")
                        .font(.title)
                        .bold()
                    Text("The easiest way to track and share your dreams with your friends")
                    Spacer()
                    VStack {
                        #if os(macOS)
                        
                        #else
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
                                }
                            case .failure(let error):
                                Task {
                                    await authManager.showError(message: error.localizedDescription)
                                }
                            }
                        }
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(20)
                        .withHoverEffect()
                        #endif
                        
                        NavigationLink(destination: SignUpView()) {
                            #if os(macOS)
                            Text("Sign up")
                                .bold()
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                            #else
                            Text("Sign up With Email")
                                .bold()
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                            #endif
                        }
                        .buttonStyle(.borderless)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(20)
                        .withHoverEffect()
#if !os(visionOS)
                        //.buttonStyle(WillButtonStyle())
#endif
                        
                        NavigationLink(destination: LoginView()) {
                            Text("Sign in")
                                .bold()
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderless)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(20)
                        .withHoverEffect()
#if !os(visionOS)
                        //.buttonStyle(WillButtonStyle())
#endif
                        Button("Continue as guest", action: {
                            confirmGuest = true
                        })
                        .buttonStyle(.plain)
                        .foregroundStyle(Color("TextColorSet"))
                    }
                    .frame(maxWidth: 500)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundStyle(.element)
                    }
                    .padding(.horizontal)
                    #if os(macOS)
                    .padding(.bottom)
                    #endif
                }
            }
        }
#if os(macOS)
.toolbar {
    ToolbarItem {
        Text("")
    }
}
#endif
        .alert(
            "Are you sure?",
            isPresented: $confirmGuest,
            actions: {
                Button("Yes") {
                    withAnimation {
                        isGuest = true
                    }
                }
                Button("No", role: .cancel) {
                    confirmGuest = false
                }
                .keyboardShortcut(.escape)
            },
            message: { Text("With an account, you can share with friends. Guest Mode won’t have this feature. Are you sure you want to continue as a guest?")
            })
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
    FirstStartup(isGuest: .constant(false))
}
