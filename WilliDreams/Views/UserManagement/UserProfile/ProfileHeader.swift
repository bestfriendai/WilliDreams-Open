//
//  ProfileHeader.swift
//  WilliWidgets
//
//  Created by William Gallegos on 29.10.2025.
//

import SwiftUI
import WilliKit
import FirebaseAuth
import FirebaseFirestore

struct ProfileHeader: View {
    @State var userToShow: User
    @State var currentUser: User
    
    @FocusState private var isEditingDescription
    
    var body: some View {
        let isPhone = (getPlatform() == .iPhone)
        let scale: CGFloat = isPhone ? 0.5 : 1.0
        
        VStack {
            HStack(spacing: getPlatform() == .iPhone ? 0 : 10) {
                if let dateCreated = userToShow.creationDate {
                    CircularTextView(title: "Account Created", radius: 120)
                        .overlay {
                            VStack {
                                Text("\(getDaysSince(eventDate: dateCreated))")
                                    .font(.largeTitle)
                                    .bold()
                                Text("Days Ago")
                            }
                        }
                        .background {
                            Circle()
                                .foregroundStyle(.element)
                        }
                        .scaleEffect(scale)
                }
                AsyncImage(url: userToShow.pfp) { image in
                    image
                        .resizable()
                        .frame(width: isPhone ? 110 : 200, height: isPhone ? 110 : 200)
                        .clipShape(Circle())
                        .background {
                            Circle()
                                .padding(-3)
                                .opacity(0.4)
                                .blur(radius: 5)
                                .foregroundStyle(.black)
                        }
                        .contentTransition(.opacity)
                } placeholder: {
                    Image("DefaultPFP")
                        .resizable()
                        .frame(width: isPhone ? 110 : 200, height: isPhone ? 110 : 200)
                        .clipShape(Circle())
                        .background {
                            Circle()
                                .padding(-3)
                                .opacity(0.4)
                                .blur(radius: 5)
                                .foregroundStyle(.black)
                        }
                }
                if let appsUsed = userToShow.appsUsed {
                    
                    CircularTextView(title: "Apps Used", rotationEffect: 330, radius: 120)
                        .overlay {
                            HStack {
                                ForEach(appsUsed, id: \.self) { appName in
                                    let appLetter = Array(appName)[5]
                                    VStack {
                                        Image(appName)
                                            .resizable()
                                            .scaledToFit()
                                            .cornerRadius(10)
                                        Text(verbatim: "W\(appLetter)")
                                    }
                                }
                            }
                            .padding()
                            .frame(maxHeight: 100)
                        }
                        .background {
                            Circle()
                                .foregroundStyle(.element)
                        }
                        .scaleEffect(scale)
                }
            }
            
            VStack {
                Text(userToShow.username)
                    .font(.title)
                    .bold()
                if currentUser.userUID == userToShow.userUID {
                    TextField("Add your profile description here!", text: Binding(get: {
                        userToShow.userDescription ?? ""
                    }, set: {
                        userToShow.userDescription = $0
                    }))
                    .textFieldStyle(WillTextFieldStyle())
                    .padding(.horizontal)
                    .focused($isEditingDescription)
                    .onDisappear {
                        changeDescription(description: userToShow.userDescription ?? "")
                    }
                    .onChange(of: isEditingDescription) {
                        if isEditingDescription == false {
                            changeDescription(description: userToShow.userDescription ?? "")
                        }
                    }
                } else {
                    if let description = userToShow.userDescription {
                        if description.isEmpty == false {
                            Text(description)
                                .font(.caption)
                        }
                    }
                }
                //Text(getScoreText(studyScore: userToShow.score ?? 0))
            }
        }
        .onAppear {
            
        }
    }
    
    func getDaysSince(eventDate: Date, currentDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        
        let startOfDay = calendar.startOfDay(for: currentDate)
        let startOfEventDay = calendar.startOfDay(for: eventDate)
        
        let components = calendar.dateComponents([.day], from: startOfEventDay, to: startOfDay)
        
        return components.day ?? 0
    }
    
    func changeDescription(description: String) {
        print("WILLIDEBUG: Updating description")
        let db = Firestore.firestore().collection("Users")
        let currentUserRef = db.document(currentUser.userUID)
        userToShow.userDescription = description
        
        currentUserRef.updateData([
            "userDescription": description
        ])
        print("WILLIDEBUG: Description updated")
    }
}

