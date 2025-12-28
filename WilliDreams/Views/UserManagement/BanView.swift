//
//  BanView.swift
//  WilliDreams
//
//  Created by William Gallegos on 3/26/25.
//

import SwiftUI
import Firebase
import WilliKit

struct BanView: View {
    @State private var bannedUntil: Date? = nil
    @State private var banReason: String = "Unknown"
    @State private var isLoading = true
    @State private var isBanned = false
    
    @AppStorage("userUID") private var userId = ""
    
    var body: some View {
        ZStack {
            UIBackground()
            if isLoading {
                WilliLoadingIndicator()
            } else if isBanned {
                VStack {
                    Image("LaunchIcon")
                        .resizable()
                        .frame(width: 100, height: 100)
                    Text("Account Banned")
                        .font(.largeTitle)
                        .bold()
                    Text("You have been banned for violating the WilliApp Terms of Service.")
                        .bold()
                    Text("Reason: \(banReason)")
                        .padding(.bottom)
                    
                    if let bannedUntil = bannedUntil {
                        Text("Ban expires in:")
                            .font(.caption)
                        Text(bannedUntil, style: .timer)
                            .font(.caption)
                    } else {
                        Text("Your account has been terminated.")
                            .font(.caption)
                    }
                    // FIX: Safely unwrap URL instead of force unwrap
                    if let supportURL = URL(string: "https://www.williamgallegos.net/support") {
                        Link(destination: supportURL,
                             label: { Text("Submit an Appeal")
                        })
                        .buttonStyle(WillButtonStyle())
                    }
                }
                .padding()
                .williBackground()
            }
        }
        .onAppear {
            fetchBanInfo()
        }
    }
    
    // FIX: Use async/await with MainActor instead of DispatchQueue
    func fetchBanInfo() {
        guard !userId.isEmpty else {
            print("WILLIDEBUG: User ID is empty.")
            isLoading = false
            return
        }

        Task {
            await fetchBanInfoAsync()
        }
    }

    @MainActor
    private func fetchBanInfoAsync() async {
        let userRef = Firestore.firestore().collection("Users").document(userId)

        do {
            let document = try await userRef.getDocument()

            guard document.exists else {
                print("WILLIDEBUG: Document does not exist for userId: \(userId)")
                isLoading = false
                return
            }

            print("WILLIDEBUG: Document Data - \(document.data() ?? [:])")

            if let bannedStatus = document.data()?["isBanned"] as? Bool, bannedStatus {
                self.isBanned = true
                self.banReason = document.data()?["banReason"] as? String ?? "No reason provided."

                if let timestamp = document.data()?["bannedUntil"] as? Timestamp {
                    self.bannedUntil = timestamp.dateValue()
                } else {
                    self.bannedUntil = nil
                }
            } else {
                print("WILLIDEBUG: User is not banned or ban data missing.")
            }

            isLoading = false
        } catch {
            print("WILLIDEBUG: Error fetching ban info: \(error.localizedDescription)")
            isLoading = false
        }
    }
}

func getIsBanned(userId: String) async -> Bool {
    let isLoggedIn = UserDefaults.standard.bool(forKey: "loginStatus")
    
    if isLoggedIn == false { return false }

    let userRef = Firestore.firestore().collection("Users").document(userId)
    
    do {
        let document = try await userRef.getDocument()
        if let data = document.data(), let isBanned = data["isBanned"] as? Bool {
            return isBanned
        }
        return false
    } catch {
        print("Error fetching ban info: \(error.localizedDescription)")
        return false
    }
}
