//
//  Profile.swift
//  WilliStudy
//
//  Created by William Gallegos on 2/24/24.
//

import SwiftUI
import Firebase
@preconcurrency import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import WilliKit

@available(*, deprecated, renamed: "WilliProfile", message: "Profile doesn't include the latest features.")
struct Profile: View {
    @Environment(\.verticalSizeClass) var isVertical
    @State private var streak = 0
    
    @State var userToShow: User
    
    @State private var dreams: [DreamCloud] = []
    @State private var dreamFetcher = DreamFetcher()
    
    @AppStorage("userUID") private var userID = ""
    
#if !os(tvOS)
    @State private var imagePickerItem: PhotosPickerItem?
#endif
    
    @State private var image: Data? = nil
    @State private var imagePickerShown = false
    
    @State private var docListener: ListenerRegistration?
    
    @State private var isFetching = true
    
    @AppStorage("loginStatus") private var isLoggedIn = false
    @AppStorage("userName") private var userName = ""
    
    @State private var paginationSet: QueryDocumentSnapshot?
    
    //@State private var studySets: [StudySetShared] = []
    
    @State private var currentUser: User? = nil
    
    @State private var blockConfirmation = false
    
    let storage = Storage.storage()
    
    var body: some View {
        let currentTime = Int(Date().timeIntervalSince1970)
        let lastStreakUpdate = userToShow.timeSinceLastStreak ?? currentTime
        
        let timeDifference = currentTime - lastStreakUpdate
        
        let streakToDisplay = timeDifference >= 28 * 3600 ? (userToShow.streak ?? 0) : 0
        
        let storageRef = storage.reference().child("userToShow-profile-pictures/\(userID).jpg")
        
        ZStack {
            if true {
                WilliProfile(user: userToShow)
            } else {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                ScrollView {
                    if currentUser?.usersBlocked?.contains(userToShow.userUID) == true {
                        VStack {
                            ContentUnavailableView("You blocked this user", systemImage: "circle.slash")
                            Button(action: {
                                guard let currentUserUID = currentUser?.userUID else { return }
                                let db = Firestore.firestore()
                                let userRef = db.collection("Users").document(currentUserUID)
                                
                                //DispatchQueue.main.async {
                                userRef.updateData([
                                    "usersBlocked": FieldValue.arrayRemove([userToShow.userUID])
                                ]) { error in
                                    if let error = error {
                                        print("Error unblocking user: \(error.localizedDescription)")
                                    } else {
                                        //print("\(userToShow.username) has been unblocked.")
                                    }
                                }
                                //}
                                
                                currentUser?.usersBlocked?.removeAll(where: {$0 == userToShow.userUID})
                            }, label: {
                                Text("Unblock")
                            })
                            .buttonStyle(CircularButtonStyle())
                        }
                    } else if userToShow.usersBlocked?.contains(currentUser?.userUID ?? "") == true {
                        VStack {
                            ContentUnavailableView("This user has blocked you.", systemImage: "circle.slash")
                        }
                    } else {
                        VStack {
                            if getPlatform() == .iPhone {
                                HStack {
                                    AsyncImage(url: userToShow.pfp) { image in
                                        image
                                            .resizable()
                                            .frame(width: 100, height: 100)
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
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .background {
                                                Circle()
                                                    .padding(-3)
                                                    .opacity(0.4)
                                                    .blur(radius: 5)
                                                    .foregroundStyle(.black)
                                            }
                                    }
                                    Spacer()
                                    VStack {
                                        Text(userToShow.username)
                                            .font(.title)
                                            .bold()
                                        //Text(getScoreText(studyScore: userToShow.score ?? 0))
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.bottom)
                                
#if !os(tvOS)
                                if userToShow.id == userID {
                                    Button(action: {
                                        imagePickerShown = true
                                    }, label: {
                                        Label(userToShow.pfp != nil ? "Change Profile Picture" : "Add Profile Picture", systemImage: "photo")
                                            .frame(maxWidth: .infinity)
                                    })
                                    .padding(.horizontal)
#if !os(visionOS)
                                    .buttonStyle(WillButtonStyle())
#endif
                                    .withHoverEffect()
                                    
                                }
#endif
                            } else {
                                HStack {
                                    AsyncImage(url: userToShow.pfp) { image in
                                        image
                                            .resizable()
                                            .frame(width: 100, height: 100)
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
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .background {
                                                Circle()
                                                    .padding(-3)
                                                    .opacity(0.4)
                                                    .blur(radius: 5)
                                                    .foregroundStyle(.black)
                                            }
                                    }
                                    .padding(.leading)
                                    VStack {
                                        Text(userToShow.username)
                                            .font(.largeTitle)
                                            .bold()
                                        //Text(getScoreText(studyScore: userToShow.score ?? 0))
                                        /*
                                         HStack {
                                         Label("\(streakToDisplay) Streak", systemImage: "flame.fill")
                                         .padding(5)
                                         .background {
                                         RoundedRectangle(cornerRadius: 90)
                                         .stroke(Color("TextColorSet"), lineWidth: 1)
                                         .foregroundStyle(.white)
                                         }
                                         Label("\(userToShow.score ?? 0) Score", systemImage: "star.circle.fill")
                                         .padding(5)
                                         .background {
                                         RoundedRectangle(cornerRadius: 90)
                                         .stroke(Color("TextColorSet"), lineWidth: 1)
                                         .foregroundStyle(.white)
                                         }
                                         }
                                         */
                                    }
                                    Spacer()
                                    HStack {
                                        VStack {
                                            if userToShow.id != userID {
                                                HStack {
                                                    if let currentUser = currentUser {
                                                        if userToShow.friends?.contains(userID) == true {
                                                            EmptyView()
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
                                                                self.currentUser?.friends = (currentUser.friends ?? []) + [userToShow.userUID]
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
                                                    } else {
                                                        ProgressView()
                                                    }
                                                    /*
                                                     Button(action: {
                                                     
                                                     }) {
                                                     Label("Follow", systemImage: "heart.fill")
                                                     .frame(maxWidth: .infinity)
                                                     }
                                                     .padding(.horizontal)
                                                     .buttonStyle(WillButtonStyle())
                                                     Button(action: {
                                                     
                                                     }) {
                                                     Label("Add Friend", systemImage: "plus.circle")
                                                     .frame(maxWidth: .infinity)
                                                     }
                                                     .padding(.horizontal)
                                                     .buttonStyle(WillButtonStyle())
                                                     */
                                                    Image(systemName: "circle.slash")
                                                        .onTapGesture {
                                                            blockConfirmation = true
                                                        }
                                                        .padding(.trailing)
                                                }
                                            } else {
                                                Button(action: {
                                                    imagePickerShown = true
                                                }, label: {
                                                    Label(userToShow.pfp != nil ? "Change Profile Picture" : "Add Profile Picture", systemImage: "photo")
                                                        .frame(maxWidth: .infinity)
                                                })
                                                .padding(.horizontal)
#if !os(visionOS)
                                                .buttonStyle(WillButtonStyle())
#endif
                                                .withHoverEffect()
                                            }
                                        }
                                        .frame(maxWidth: 250)
                                        
                                    }
                                }
                                .padding(.top)
                            }
                            Divider()
                            
                            HStack {
                                Text("Public Dreams:")
                                    .font(.body)
                                    .underline()
                                    .multilineTextAlignment(.leading)
                                    .padding(.leading)
                                Spacer()
                            }
                            VStack {
                                ForEach(dreams) { dream in
                                    DreamNetworkView(dream: dream)
                                }
                            }
                            
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
                .onAppear {
                    if docListener == nil {
                        docListener = Firestore.firestore().collection("Users").document(userToShow.id ?? "").addSnapshotListener({ snapshot, error in
                            if let snapshot {
                                if snapshot.exists {
                                    if let updatedUser = try? snapshot.data(as: User.self) {
                                        withAnimation {
                                            userToShow = updatedUser
                                        }
                                    }
                                } else {
                                    
                                }
                            }
                        })
                    }
                }
                .task {
                    dreams = await dreamFetcher.fetchUserDreams(userID: userToShow.userUID, shouldMerge: false).filter({$0.isArchived == false})
                }
                .task {
                    do {
                        currentUser = try await fetchCurrentUser()
                    } catch {
                        // Handle errors here (optional)
                        print("error")
                    }
                }
                .alert(
                    "Block User",
                    isPresented: $blockConfirmation,
                    actions: {
                        Button(
                            action: {
                                guard let currentUserUID = currentUser?.userUID else { return }
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
                                
                                currentUser?.usersBlocked = (currentUser?.usersBlocked ?? []) + [userToShow.userUID]
                                
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
    }
}

func getScoreText(studyScore: Int) -> String {
    if studyScore >= 10000000 {
        return "Legendary Studier"
    } else if studyScore >= 1000000 {
        return "Epic Studier"
    } else if studyScore >= 100000 {
        return "Elite Studier"
    } else if studyScore >= 50000 {
        return "Master Studier"
    } else if studyScore >= 10000 {
        return "Expert Studier"
    } else if studyScore >= 5000 {
        return "Advanced Studier"
    } else if studyScore >= 1000 {
        return "Intermediate Studier"
    } else if studyScore >= 500 {
        return "Junior Studier"
    } else if studyScore >= 100 {
        return "Novice Studier"
    } else if studyScore >= 50 {
        return "Beginner Studier"
    } else if studyScore >= 20 {
        return "Aspiring Studier"
    } else if studyScore >= 10 {
        return "New Studier"
    } else {
        return "Just Starting"
    }
}
