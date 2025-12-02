//
//  Manage.swift
//  WilliStudy
//
//  Created by William Gallegos on 7/20/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import WilliKit

struct ManageAccountView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    //@State private var studySets: [StudySetShared] = []
    @State private var deleteAccountPrompt = false
    @State private var resetPasswordPrompt = false
    
    @AppStorage("loginStatus") private var isLoggedIn = false
    
    @State var user: User
    
    
    var body: some View {
        ZStack {
            UIBackground()
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack {
                if #unavailable(macOS 26) {
                    Text("")
                }
                VStack(alignment: .leading) {
                    Text("Account Details")
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                        .font(.headline)
                        .underline()
                        .padding(.top, 5)
                    
                    VStack {
                        Button(action: {
                            resetPassword()
                        }, label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .frame(width: 30)
                                Text("Reset Password")
                                Spacer()
                            }
                            .foregroundStyle(.foreground)
                            .padding()
                        })
                        .buttonStyle(.borderless)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundStyle(.element)
                        }
                        .withHoverEffect()
                        
                            Button(action: {
                                deleteAccountPrompt = true
                            }, label: {
                                HStack {
                                    Image(systemName: "trash")
                                        .frame(width: 30)
                                    Text("Delete Account")
                                    Spacer()
                                }
                                .foregroundStyle(.foreground)
                                .padding()
                            })
                            .buttonStyle(.borderless)
                            .background {
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundStyle(.element)
                            }
                            .withHoverEffect()
                            
                            Text("We will keep your dreams on this device so if you choose to create a new account, you can continue to use your dreams..")
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal)
                                .font(.caption)
                                .padding(.top, 5)
                        
                    }
                    .padding(.horizontal)
                }
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(.element)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .alert("Delete Account", isPresented: $deleteAccountPrompt, actions: {
            Button("Confirm", role: .destructive) {
                deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        }, message: {
            Text("Are you sure you want to delete your account? This action is permanent.")
        })
        .alert("Reset Password Sent", isPresented: $resetPasswordPrompt, actions: {}, message: {Text("Please check your email to reset your password.")})
    }
    
    func resetPassword() {
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: user.userEmail)
                resetPasswordPrompt = true
            } catch {
            }
        }
    }

    func deleteAccount() {
        Auth.auth().currentUser?.delete { error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                isLoggedIn = false
            }
        }
    }
}
