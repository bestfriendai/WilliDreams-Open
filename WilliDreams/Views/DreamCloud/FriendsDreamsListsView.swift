//
//  FriendsDreamsListsView.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/30/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import WilliKit

struct FriendDreamListView: View {
    @Environment(\.modelContext) var modelContext
    
    @Binding var dreams: [DreamCloud]
    @State private var isFetching = true
    
    @AppStorage("loginStatus") private var isLoggedIn = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("userUID") private var userID = ""
    
    @State private var paginationSet: QueryDocumentSnapshot?
    
    @State private var dreamFetcher = DreamFetcher()
    @State private var currentUser: User?
    
    @State private var dateToLoad: Date = Calendar.current.startOfDay(for: Date.now)
    
    var body: some View {
        ScrollView {
            HStack {
                if #available(iOS 26, macOS 26, *) {
                    Button(action: {
                        withAnimation {
                            dateToLoad = Calendar.current.startOfDay(for: dateToLoad.addingTimeInterval((-1) * 86400))
                        }
                    }, label: {
                        Image(systemName: "arrow.left")
                    })
                    .buttonStyle(GlassProminentButtonStyle())
                } else {
                    Button(action: {
                        withAnimation {
                            dateToLoad = Calendar.current.startOfDay(for: dateToLoad.addingTimeInterval((-1) * 86400))
                        }
                    }, label: {
                        Image(systemName: "arrow.left")
                    })
                    .buttonStyle(CircularButtonStyle())
                }
                Spacer()
                
                DatePicker("", selection: $dateToLoad, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                Spacer()
                
                if #available(iOS 26, macOS 26, *) {
                    Button(action: {
                        withAnimation {
                            dateToLoad = Calendar.current.startOfDay(for: dateToLoad.addingTimeInterval(86400))
                        }
                    }, label: {
                        Image(systemName: "arrow.right")
                    })
                    .buttonStyle(GlassProminentButtonStyle())
                    .disabled(dateToLoad.addingTimeInterval(86400) > Date.now)
                    .opacity(dateToLoad.addingTimeInterval(86400) > Date.now ? 0 : 1)
                } else {
                    Button(action: {
                        withAnimation {
                            dateToLoad = Calendar.current.startOfDay(for: dateToLoad.addingTimeInterval(86400))
                        }
                    }, label: {
                        Image(systemName: "arrow.right")
                    })
                    .buttonStyle(CircularButtonStyle())
                    .disabled(dateToLoad.addingTimeInterval(86400) > Date.now)
                    .opacity(dateToLoad.addingTimeInterval(86400) > Date.now ? 0 : 1)
                }
                
            }
            .padding(.horizontal)
            
            VStack {
                if !isLoggedIn {
                    if getPlatform() != .iPhone {
                        Text("")
                    }
                    HStack {
                        HStack {
                            Spacer()
                            Image(systemName: "person.crop.circle")
                                .font(.largeTitle)
                            Text("WilliDreams is better with an account!")
                            Spacer()
                            VStack {
                                NavigationLink(destination: SignUpView(), label: {
                                    Text("Sign Up")
                                        .frame(width: 70)
                                })
                                .buttonStyle(.borderedProminent)
                                NavigationLink(destination: LoginView(), label: {
                                    Text("Log In")
                                        .frame(width: 70)
                                })
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.all, 5)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundStyle(.gray)
                                .opacity(0.2)
                        }
                    }
                    .padding(.horizontal, 5)
                }
                if isFetching {
                    VStack {
                        Spacer()
                        Text("Finding dreams...")
                            .font(.title)
                            .bold()
                        WilliLoadingIndicator(isForNetwork: true)
                            .offset(y: 20)
                        Spacer()
                    }
                } else {
                    VStack {
                        if dreams.isEmpty {
                            Text("None of your friends have uploaded their dreams yet.")
                        } else {
                            #if os(macOS)
                            Text("")
                            #endif
                            ForEach(dreams) { dream in
                                DreamNetworkView(dream: dream)
                            }
                        }
                    }
                    .frame(maxWidth: 500)
                }
                Rectangle()
                    .opacity(0)
                    .frame(height: 100)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Friends")
        .refreshable {
            //Task {
                do {
                    dreams = try await dreamFetcher.fetchFriendsDreams()
                } catch {
                    print("WILLIDEBUG: Error getting friends dreams")
                }
           // }
        }
        .onChange(of: dateToLoad) {
            Task {
                isFetching = true
                do {
                    dreams = try await dreamFetcher.fetchFriendsDreams(date: dateToLoad)
                } catch {
                    print("WILLIDEBUG: Error getting friends dreams")
                }
                isFetching = false
            }
        }
        .frame(maxWidth: .infinity)
        .task {
            isFetching = true
            do {
                dreams = try await dreamFetcher.fetchFriendsDreams(date: dateToLoad)
            } catch {
                print("WILLIDEBUG: Error getting friends dreams")
            }
            isFetching = false
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: FriendAdder()) {
                    Image(systemName: "person.fill.badge.plus")
                }
            }
        }
    }
}
