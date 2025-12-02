//
//  ProfileOptions.swift
//  WilliWidgets
//
//  Created by William Gallegos on 29.10.2025.
//

import SwiftUI
import WilliKit
import FirebaseFirestore

struct ProfileOptions: View {
    @State var userToShow: User
    @State var currentUser: User
    
    @State private var blockConfirmation = false
    @State private var reportScreenShown = false
    
    @AppStorage("userUID") private var userID = ""
    @AppStorage("loginStatus") private var isLoggedIn = false
    @AppStorage("userName") private var userName = ""
    
    @State private var image: Data? = nil
    @State private var imagePickerShown = false
    
    var body: some View {
        AStack(isVertical: getPlatform() == .iPhone) {
            if userToShow.id == userID {
                Button(action: {
                    imagePickerShown = true
                }, label: {
                    Label(userToShow.pfp != nil ? "Change Profile Picture" : "Add Profile Picture", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                })
                .padding(.horizontal)
                .buttonStyle(WillButtonStyle())
                .withHoverEffect()
                
            } else {
                if userToShow.friends?.contains(userID) == true {
                    Text("You are friends!")
                } else if userToShow.friendRequestsReceived?.contains(currentUser.userUID) == true {
                    Button(action: {
                        
                    }, label: {
                        Text("Pending")
                            .frame(maxWidth: .infinity)
                    })
                    .padding(.horizontal)
                    .buttonStyle(WillButtonStyle(backgroundColor: .gray))
                    .disabled(true)
                } else if currentUser.friendRequestsReceived?.contains(userToShow.userUID) == true {
                    Button(action: {
                        self.currentUser.friends = (currentUser.friends ?? []) + [userToShow.userUID]
                        userToShow.friends = (userToShow.friends ?? []) + [currentUser.userUID]
                        
                        let db = Firestore.firestore().collection("Users")
                        let currentUserRef = db.document(currentUser.userUID)
                        let userToShowRef = db.document(userToShow.userUID)
                        
                        Task {
                            try await currentUserRef.updateData([
                                "friends": FieldValue.arrayUnion([userToShow.userUID])
                            ])
                            try await userToShowRef.updateData([
                                "friends": FieldValue.arrayUnion([currentUser.userUID])
                            ])
                        }
                    }, label: {
                        Label("Accept", systemImage: "person.fill.badge.plus")
                            .frame(maxWidth: .infinity)
                    })
                    .padding(.horizontal)
                    .buttonStyle(WillButtonStyle())
                } else {
                    Button(action: {
                        userToShow.friendRequestsReceived = (userToShow.friendRequestsReceived ?? []) + [currentUser.userUID]
                        
                        let db = Firestore.firestore().collection("Users")
                        let userToShowRef = db.document(userToShow.userUID)
                        
                        Task {
                            try await userToShowRef.updateData([
                                "friendRequestsReceived": FieldValue.arrayUnion([currentUser.userUID])
                            ])
                        }
                    }, label: {
                        Label("Add Friend", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                    })
                    .padding(.horizontal)
                    .buttonStyle(WillButtonStyle())
                }
            }
        }
        .sheet(isPresented: $imagePickerShown) {
            ImagePicker(imageToEdit: $image)
        }
        .onChange(of: image) {
            Task {
                if let data = image {
                    //let compressedData = compressImage(data: data) // Call compression function
                    uploadProfilePicture(data: data, userID: userID) { (imageUrl, error) in
                        if let error = error {
                            print("Error uploading image: \(error.localizedDescription)")
                            // Handle error (e.g., show error message to userToShow)
                        } else {
                            updateUserProfilePicture(imageUrl: imageUrl!, userID: userID) // Update profile with URL
                        }
                    }
                }
            }
        }
        .alert(
            "Block User",
            isPresented: $blockConfirmation,
            actions: {
                Button(
                    action: {
                        let currentUserUID = currentUser.userUID
                        let db = Firestore.firestore()
                        let userRef = db.collection("Users").document(currentUserUID)
                        
                        userRef.updateData([
                            "usersBlocked": FieldValue.arrayUnion([userToShow.userUID])
                        ]) { error in
                            if let error = error {
                                print("Error blocking user: \(error.localizedDescription)")
                            } else {
                                //print("WILLIDEBUG: \(userToShow.username) has been blocked.")
                            }
                        }
                        
                        currentUser.usersBlocked = (currentUser.usersBlocked ?? []) + [userToShow.userUID]
                        
                        blockConfirmation = false
                    },
                    label: {
                        Text("Block")
                    }
                )
                .keyboardShortcut(.defaultAction)
                
                Button(
                    action: {
                        blockConfirmation = false
                    },
                    label: {
                        Text("Cancel")
                    })
            },
            message: {Text("Are you sure you wish to block \(userToShow.username)?")})
    }
}
