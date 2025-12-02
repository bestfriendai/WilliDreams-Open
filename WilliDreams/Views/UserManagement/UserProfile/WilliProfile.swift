//
//  WilliProfile.swift
//  WilliWidgets
//
//  Created by William Gallegos on 29.10.2025.
//

import SwiftUI
import WilliKit
import FirebaseFirestore

struct WilliProfile: View {
    @State var user: User
    @State private var currentUser: User? = nil
    
    var body: some View {
        ZStack {
            UIBackground()
            if currentUser?.usersBlocked?.contains(user.userUID) == true {
                VStack {
                    ContentUnavailableView("You blocked this user", systemImage: "circle.slash")
                    Button(action: {
                        guard let currentUserUID = currentUser?.userUID else { return }
                        let db = Firestore.firestore()
                        let userRef = db.collection("Users").document(currentUserUID)
                        
                        userRef.updateData([
                            "usersBlocked": FieldValue.arrayRemove([user.userUID])
                        ]) { error in
                            if let error = error {
                                print("WILLIDEBUG: Error unblocking user: \(error.localizedDescription)")
                            } else {
                                print("WILLIDEBUG: \(user.username) has been unblocked.")
                            }
                        }
                        
                        currentUser?.usersBlocked?.removeAll(where: {$0 == user.userUID})
                    }, label: {
                        Text("Unblock")
                    })
                    .buttonStyle(CircularButtonStyle())
                }
            } else if currentUser == nil {
                WilliLoadingIndicator(isForNetwork: true)
            } else {
                if let currentUser = currentUser {
                    ScrollView {
                        ProfileHeader(userToShow: user, currentUser: currentUser)
                        ProfileOptions(userToShow: user, currentUser: currentUser)
                        Divider()
                        AppUserContent(userToShow: user)
                    }
                }
            }
        }
        .task {
            do {
                currentUser = try await fetchCurrentUser()
                
            } catch {
                // Handle errors here (optional)
                print("WILLIDEBUG: " + error.localizedDescription)
            }
        }
    }
}
