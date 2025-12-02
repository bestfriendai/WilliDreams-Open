//
//  ProfileNavigationLink.swift
//  WilliDreams
//
//  Created by William Gallegos on 3/2/25.
//

import SwiftUI
import FirebaseFirestore

struct ProfileNavigationLink: View {
    var dream: DreamCloud
    
    @State private var userWhoPosted: User?
    @State private var userProfileShown = false
    
    var body: some View {
        HStack {
            Button(action: {userProfileShown = true}, label: {
                HStack {
                    if let user = userWhoPosted {
                        AsyncImage(url: user.pfp) { image in
                            image
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .background {
                                    Circle()
                                        .foregroundStyle(.black)
                                }
                        } placeholder: {
                            Image("DefaultPFP")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .background {
                                    Circle()
                                        .foregroundStyle(.black)
                                }

                        }
                    } else {
                        Image("DefaultPFP")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .background {
                                Circle()
                                    .foregroundStyle(.black)
                            }
                    }
                    VStack {
                        if let user = userWhoPosted {
                            HStack {
                                Text(user.username)
                                    .font(.headline)
                                Spacer()
                            }
                        }
                        
                        HStack {
                            Text(dream.name)
                            Spacer()
                        }
                    }
                    .multilineTextAlignment(.leading)
                }
            })
            .buttonStyle(.borderless)
            .withHoverEffect()
        }
        .foregroundStyle(.primary)
        .task {
            userWhoPosted = await getUser(userID: dream.author)
        }
        .navigationDestination(isPresented: $userProfileShown) {
            if let user = userWhoPosted {
                Profile(userToShow: user)
            } else {
                Text("Loading")
            }
        }
    }
}

