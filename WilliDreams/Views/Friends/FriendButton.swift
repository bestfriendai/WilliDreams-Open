//
//  FriendButton.swift
//  WilliDreams
//
//  Created by William Gallegos on 3/1/25.
//

import SwiftUI
import FirebaseFirestore
import WilliKit

struct FriendButton: View {
    @State var currentUser: User
    @State var userToShow: User
    
    var body: some View {
        NavigationLink(destination: Profile(userToShow: userToShow)) {
           // if userToShow.friends?.contains(currentUser.userUID) == true {
                //EmptyView()
           // } else {
                HStack {
                    AsyncImage(url: userToShow.pfp) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .background {
                                Circle()
                                    .opacity(0.4)
                                    .foregroundStyle(.black)
                            }
                            .contentTransition(.opacity)
                    } placeholder: {
                        Image("DefaultPFP")
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .background {
                                Circle()
                                    .foregroundStyle(.black)
                            }
                    }
                    VStack {
                        Text(userToShow.username)
                            .bold()
                    }
                    .foregroundStyle(Color.textColorSet)
                    Spacer()
                    Group {
                        if userToShow.friends?.contains(currentUser.userUID) == true {
                            EmptyView()
                        } else if userToShow.friendRequestsReceived?.contains(currentUser.userUID) == true {
                            Text("Pending")
                                .foregroundStyle(.gray)
                                .padding(6)
                                .background {
                                    Capsule()
                                        .stroke(.gray)
                                }
                        } else if currentUser.friendRequestsReceived?.contains(userToShow.userUID) == true {
                            Button(action: {
                                currentUser.friends = (currentUser.friends ?? []) + [userToShow.userUID]
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
                                HStack {
                                    Image(systemName: "person.fill.badge.plus")
                                    Text("Accept")
                                }
                                .foregroundStyle(.white)
                                .padding(6)
                                .background {
                                    Capsule()
                                        .foregroundStyle(Color.accentColor)
                                }
                            })
                            .buttonStyle(.borderless)
                            .layoutPriority(1)
                            .withHoverEffect()
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
                                HStack {
                                    Image(systemName: "person.fill.badge.plus")
                                    Text("Add Friend")
                                }
                                .foregroundStyle(.white)
                                .padding(6)
                                .background {
                                    Capsule()
                                        .foregroundStyle(Color.accentColor)
                                }
                            })
                            .buttonStyle(.borderless)
                            .layoutPriority(1)
                            .withHoverEffect()
                        }
                    }
                }
                .frame(height: 60)
                .williBackground()
                .padding(.horizontal)
            //}
        }
        .buttonStyle(.borderless)
    }
}
