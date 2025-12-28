//
//  FriendAdder.swift
//  WilliDreams
//
//  Created by William Gallegos on 2/22/25.
//

import SwiftUI
import FirebaseFirestore
import WilliKit

struct FriendAdder: View {
    @State private var isFetching = false
    @State private var usernameInput: String = ""
    @State private var friendsFound: [User] = []
    
    @State private var currentUser: User?
    
    @State private var userRequests: [User] = []
    
    var contactSyncing = ContactSyncing()
    
    @State private var areaCode: String = ""
    @State private var phoneNumberInput: String = ""
    @State private var phoneNumberPromptShown = false
    
    @State private var contactSyncPermissionGranted: Bool? = nil
    
    @AppStorage("thisAppUsersOnly") private var thisAppUsersOnly: Bool = true
    
    @State private var contacts: [User] = []

    // FIX: Add debounce task for search
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            UIBackground()
            VStack {
                if let currentUser = currentUser {
                    if usernameInput.isEmpty {
                        if !(currentUser.friendRequestsReceived?.isEmpty == true) {
                            ScrollView {
                                HStack {
                                    Text("Added me")
                                        .font(.caption)
                                    Spacer()
                                }
                                .padding(.leading)
                                
                                ForEach(userRequests) { friend in
                                    if currentUser.friends?.contains(friend.userUID) == false {
                                        FriendButton(currentUser: currentUser, userToShow: friend)
                                    }
                                }
                                
                                if let contactSyncPermissionGranted = contactSyncPermissionGranted {
                                    if contactSyncPermissionGranted {
                                        if contacts.isEmpty == false {
                                            HStack {
                                                Text("My Contacts")
                                                    .font(.caption)
                                                Spacer()
                                            }
                                            .padding(.leading)
                                            ForEach(contacts) { friend in
                                                if currentUser.friends?.contains(friend.userUID) == false {
                                                    FriendButton(currentUser: currentUser, userToShow: friend)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            // FIX: Fixed typo "recieved" -> "received"
                            ContentUnavailableView("No Friend Requests Received", systemImage: "person.3.fill", description: Text("Try searching for a user above."))
                        }
                    } else {
                        if isFetching {
                            ProgressView()
                        } else {
                            if friendsFound.isEmpty == false {
                                ScrollView {
                                    Toggle("Show WilliDreams Users Only", isOn: $thisAppUsersOnly)
                                        .padding(5)
                                        .background {
                                            RoundedRectangle(cornerRadius: 20)
                                                .foregroundStyle(.gray.opacity(0.2))
                                        }
                                        .padding(.horizontal)
                                    ForEach(friendsFound) { friend in
                                        if thisAppUsersOnly {
                                            if friend.appsUsed?.contains("WilliDreams") == true {
                                                FriendButton(currentUser: currentUser, userToShow: friend)
                                            }
                                        } else {
                                            FriendButton(currentUser: currentUser, userToShow: friend)
                                        }
                                    }
                                }
                            } else {
                                ContentUnavailableView("No Friends Found", systemImage: "person.fill.questionmark")
                            }
                        }
                    }
                }

                // FIX: Simplified condition - only show prompt when permission NOT granted
                Group {
                    if contactSyncPermissionGranted == false {
                        VStack {
                            Text("Allow contact access to WilliDreams so you add your friends!")
                            Button(action: {
                                Task {
                                    let isAllowed = await contactSyncing.requestContactsPermission()
                                    self.contactSyncPermissionGranted = isAllowed
                                }
                            }, label: {
                                Text("Sync Contacts")
                            })
                            .buttonStyle(WillButtonStyle())
                        }
                        .williBackground()
                    }
                }
                .padding(.bottom)
            }
            .searchable(text: $usernameInput)
            .navigationTitle("Add Friends")
            .onChange(of: usernameInput) {
                // FIX: Debounce search to avoid firing on every keystroke
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
                    guard !Task.isCancelled else { return }
                    await searchUsers()
                }
            }
            .task {
                do {
                    userRequests = []
                    currentUser = try await fetchCurrentUser()
                    
                    for idRequest in currentUser?.friendRequestsReceived ?? [] {
                        let friend = await getUser(userID: idRequest)

                        if let friendRequest = friend {
                            if friendRequest.userUID != currentUser?.userUID {
                                userRequests.append(friendRequest)
                            }
                        }
                    }
                } catch {
                    print("error")
                }
            }
        }
        .task {
            contactSyncPermissionGranted = await contactSyncing.isGranted()
        }
        .onChange(of: contactSyncPermissionGranted) {
            if let perms = contactSyncPermissionGranted {
                if perms == true {
                    Task {
                        let user = try await fetchCurrentUser()
                        if let user = user {
                            if user.phoneNumber == nil {
                                phoneNumberPromptShown = true
                            } else {
                                // FIX: Use let instead of var since value isn't mutated
                                let fetchedUsers = await contactSyncing.getContactsAndCheckUsers()
                                contacts = fetchedUsers
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $phoneNumberPromptShown) {
            PhoneNumberInput(contacts: $contacts)
        }
    }
    
    func searchUsers() async {
        isFetching = true
        do {
            friendsFound = []
            let queryLowerCased = usernameInput.lowercased()
            
            let documents = try await Firestore.firestore().collection("Users")
                .whereField("username", isGreaterThanOrEqualTo: queryLowerCased)
                .whereField("username", isLessThanOrEqualTo: "\(queryLowerCased)\u{f8ff}")
                .getDocuments()
            
            let users = try documents.documents.compactMap { doc -> User? in
                try doc.data(as: User.self)
            }
            
            await MainActor.run(body: {
                friendsFound = users
            })
        } catch {
            print(error.localizedDescription)
        }
        isFetching = false
    }
}

#Preview {
    NavigationStack {
        FriendAdder()
    }
}
