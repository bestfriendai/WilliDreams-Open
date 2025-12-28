//
//  Settings.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/25/24.
//

import SwiftUI
import WilliKit
import SwiftData
import FirebaseAuth

struct SettingsContent: View {
    @State private var isPhone = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
        
    @Query private var dreams: [Dream]
    
    @AppStorage("loginStatus") private var isLoggedIn = false
    @AppStorage("canAIProcess") private var canAIProcess = true
    @AppStorage("aiSummary") private var aiSummary = ""

    @State private var user: User?
    
    @State private var errorFound = false
    
    init() {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.isPhone = true
        }
        #endif
    }
    
    var body: some View {
        Form {
            Section("About WilliDreams") {
                NavigationLink(destination: AboutApp(), label: {
                    HStack {
                        Image(systemName: "info.circle")
                            .frame(width: 30)
                        Text("About WilliDreams")
                    }
                })
            }
            .williFormElement(colorScheme: colorScheme)

            Section("Preferences") {
                Toggle(isOn: $canAIProcess) {
                    HStack {
                        Image(systemName: "sparkles")
                            .frame(width: 30)
                        Text("AI Summarization")
                    }
                    .foregroundStyle(.primary)
                }
                .labelStyle(.titleAndIcon)
            }
            .williFormElement(colorScheme: colorScheme)
            
            /*
            Section("WilliApps") {
                Link(destination: URL(string: "https://apps.apple.com/us/app/williwidgets/id1672879907")!, label: {
                    HStack {
                        Image("WilliWidgets")
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                        VStack(alignment: .leading) {
                            Text("WilliWidget")
                                .bold()
                            Text("A widget app with a bunch of pre-made and heavily customizable widgets!")
                                .font(.caption)
                        }
                        Spacer()
                    }
                })
                .frame(height: 60)
                
                Link(destination: URL(string: "https://apps.apple.com/us/app/willistudy/id6466582450")!, label: {
                    HStack {
                        Image("WilliStudy")
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                        VStack(alignment: .leading) {
                            Text("WilliStudy")
                                .bold()
                            Text("A free but very powerful studying app, designed to be a fierce competitor to Quizlet!")
                                .font(.caption)
                        }
                        Spacer()
                    }
                })
                .frame(height: 60)
                
                Link(destination: URL(string: "https://apps.apple.com/us/app/willidreams/id6553981777")!, label: {
                    HStack {
                        Image("WilliDreams")
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                        VStack(alignment: .leading) {
                            Text("WilliDreams")
                                .bold()
                            Text("A free dream tracking app where you can also share your dreams with your friends!")
                                .font(.caption)
                        }
                        Spacer()
                    }
                })
                .frame(height: 60)
            }
            .multilineTextAlignment(.leading)
            .foregroundStyle(.primary)
             */
            
            /*
            Link(destination: URL(string: "https://buymeacoffee.com/williapple")!) {
                HStack {
                    Label("Support Development", systemImage: "dollarsign")
                    Spacer()
                }
            }
            .williFormElement(colorScheme: colorScheme)
            .foregroundStyle(.primary)
             */
            
            if isLoggedIn == true {
                if let userAccount = user {
                    Section("My Account") {
                        NavigationLink(
                            destination: Profile(
                                userToShow: userAccount
                            ),
                            label: {
                                HStack {
                                    Image(systemName: "person.crop.circle")
                                        .frame(width: 30)
                                    Text("My Profile")
                                }
                                .foregroundStyle(Color("TextColorSet"))
                            }
                        )
                        .labelStyle(.titleAndIcon)
                        
                        NavigationLink(destination: ManageAccountView(user: userAccount)) {
                            HStack {
                                Image(systemName: "person.2.badge.gearshape.fill")
                                    .frame(width: 30)
                                Text("Manage Account")
                            }
                            .foregroundStyle(Color("TextColorSet"))
                        }
#if !os(macOS)
                        Button(action: {
                            signOut()
                        }) {
                            HStack {
                                Image(systemName: "door.right.hand.open")
                                    .frame(width: 30)
                                Text("Sign Out")
                            }
                            .foregroundStyle(.red)
                        }
                        .labelStyle(.titleAndIcon)
#endif
                    }
                    .williFormElement(colorScheme: colorScheme)

                } else {
                    Section(errorFound ? "Error" : "") {
                        if errorFound {
                            Text("An error was found, press below to fix.")
                            
                        }
                    }
                    .williFormElement(colorScheme: colorScheme)
                }
            }
            Section(content: {
                #if !os(macOS)
                if isLoggedIn == true {
                    Button(action: {
                        isLoggedIn = false
                    }) {
                        HStack {
                            Image(systemName: "wrench.adjustable.fill")
                                .frame(width: 30)
                            Text("Fix Account Issues")
                        }
                        .foregroundStyle(Color("TextColorSet"))
                    }
                    .labelStyle(.titleAndIcon)
                    .williFormElement(colorScheme: colorScheme)
                }
                #endif
            }, footer: {
                #if os(macOS)
                if isLoggedIn == true {
                    Button(action: {
                        signOut()
                    }) {
                        HStack {
                            Image(systemName: "door.right.hand.open")
                                .frame(width: 30)
                            Text("Sign Out")
                        }
                    }
                    .labelStyle(.titleAndIcon)
                }
                if isLoggedIn == true {
                    Button(action: {
                        isLoggedIn = false
                    }) {
                        HStack {
                            Image(systemName: "wrench.adjustable.fill")
                                .frame(width: 30)
                            Text("Fix Account Issues")
                        }
                        .foregroundStyle(Color("TextColorSet"))
                    }
                    .labelStyle(.titleAndIcon)
                }
#endif
            })
        }
        .task {
            do {
                user = try await fetchCurrentUser()
            } catch {
                print("error")
            }
        }
        .onChange(of: isLoggedIn) {
            if isLoggedIn == false {
                for dream in dreams {
                    modelContext.delete(dream)
                }
                aiSummary = ""
            }
        }
        .formStyle(.grouped)
        .williFormBackground(colorScheme: colorScheme)
        .navigationTitle("Settings")
    }

    /// Properly signs out the user from Firebase Auth and clears local state
    private func signOut() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            print("WILLIDEBUG: Error signing out: \(error.localizedDescription)")
            // Still set isLoggedIn to false to allow retry
            isLoggedIn = false
        }
    }
}
