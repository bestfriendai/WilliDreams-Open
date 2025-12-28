//
//  MyDreams.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/18/24.
//

import SwiftUI
import SwiftData
import WilliKit
import Firebase
import FirebaseFirestore

struct MyDreams: View {
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("loginStatus") private var isLoggedIn = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("userUID") private var userID = ""
    
    @Query(
        filter: #Predicate<Dream> {
            $0.isArchived == false
        },
        sort: \Dream.date,
        order: .reverse) private var dreams: [Dream]
    
    @State private var dreamFetcher = DreamFetcher()
    @State private var dreamLoggerShown = false
    @State private var archivedDreamsShown = false
    
    var body: some View {
        ZStack {
            UIBackground()
            VStack {
                if dreams.isEmpty {
                    ContentUnavailableView("No Dreams Logged", systemImage: "moon.stars.fill", description: Text("There are no dreams to display. Log one below!"))
                } else {
                    ScrollView {
                        VStack {
                            ForEach(dreams) { dream in
                                HStack {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text(dream.date, style: .date)
                                                .font(.caption)
                                            Spacer()
                                            switch getDreamStatus(dreamScale: dream.nightmareScale) {
                                            case .great:
                                                Text("Great")
                                                    .font(.caption)
                                                    .foregroundStyle(.green)
                                            case .good:
                                                Text("Good")
                                                    .font(.caption)
                                                    .foregroundStyle(.green)
                                            case .ok:
                                                Text("Ok")
                                                    .font(.caption)
                                                    .foregroundStyle(.yellow)
                                            case .bad:
                                                Text("Bad")
                                                    .font(.caption)
                                                    .foregroundStyle(.red)
                                            case .nightmare:
                                                Text("Nightmare")
                                                    .font(.caption)
                                                    .foregroundStyle(.red)
                                            }
                                        }
                                        Text(dream.name)
                                            .font(.title)
                                            .bold()
                                        RoundedRectangle(cornerRadius: 20)
                                            .frame(height: 1)
                                            .foregroundStyle(.gray)
                                        Text(dream.dreamDescription)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                .williBackground()
                                .contextMenu {
                                    Button(action: {
                                        withAnimation {
                                            // Update locally
                                            dream.isArchived = true
                                            // Sync the update to Firebase
                                            dreamFetcher.syncDreamToCloud(dream: dream, userID: userID)
                                        }
                                    }, label: {
                                        Label("Archive", systemImage: "archivebox")
                                    })
                                    
                                    Button(action: {
                                        withAnimation {
                                            // Delete locally
                                            modelContext.delete(dream)
                                            // Sync deletion to Firebase
                                            dreamFetcher.deleteDreamFromCloud(dream: dream, userID: userID)
                                        }
                                    }, label: {
                                        Label("Delete", systemImage: "trash")
                                    })
                                }
                            }
                            // FIX: Use consistent spacer across platforms
                            Spacer()
                                .frame(height: 100)
                        }
                        .padding(.horizontal)
                    }
                }
            }
             
        }
#if os(iOS)
        .overlay {
            if #available(iOS 26, *) {
                VStack(alignment: .trailing) {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            dreamLoggerShown.toggle()
                        }, label: {
                            HStack {
                                Image(systemName: "square.and.pencil")
                                Text("New Dream")
                            }
                                .foregroundStyle(.white)
                            //.foregroundStyle(.white)
                                .padding(10)
                        })
                        .glassEffect(.regular.interactive().tint(.accentColor))
                        Spacer()
                    }
                }
                .padding(.bottom)
            } else {
                VStack {
                    Spacer()
                    Button(action: {
                        dreamLoggerShown.toggle()
                    }, label: {
                        Label("New Dream", systemImage: "plus")
                            .foregroundStyle(.white)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 90)
                                    .foregroundStyle(.darkAccent)
                            }
                    })
                }
                .padding(.bottom)
            }
        }
        #endif
        .task {
            print("WILLIDEBUG: Fetching dreams from Firebase...")
            dreamFetcher.syncAllDreamsToCloud(userID: userID)
            await fetchDreams()
            
            print("WILLIDEBUG: Listening for dream changes from Firebase...")
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if #available(iOS 26, *) {
                    Menu("", systemImage: "ellipsis") {
                        Button("View Archive", systemImage: "archivebox") { archivedDreamsShown.toggle() }
                    }
                } else {
                    Menu("", systemImage: "ellipsis.circle") {
                        Button("View Archive", systemImage: "archivebox") { archivedDreamsShown.toggle() }
                    }
                }
            }
            
#if os(macOS)
            if #available(macOS 26, *) {
                ToolbarSpacer(.fixed)
            }
            
            ToolbarItem {
                if #available(macOS 26.0, visionOS 26.0, *) {
                    Button(action: {
                        dreamLoggerShown.toggle()
                    }, label: {
                        HStack {
                            Image(systemName: "square.and.pencil")
                            Text("New Dream")
                        }
                    })
                } else {
                    Button(action: {
                        dreamLoggerShown.toggle()
                    }, label: {
                        Label("New Dream", systemImage: "plus")
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(.white)
                            .padding(.all, 6)
                            .background {
                                RoundedRectangle(cornerRadius: 90)
                                    .foregroundStyle(.darkAccent)
                            }
                    })
                    .buttonStyle(.plain)
                }
            }
#endif
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $dreamLoggerShown) {
            NavigationStack {
                ZStack {
                    UIBackground()
                    DreamLogView()
                }
            }
        }
        #elseif os(macOS)
        .sheet(isPresented: $dreamLoggerShown) {
            NavigationStack {
                DreamLogView()
            }
            .frame(width: 500, height: 500)
        }
        #endif

        .sheet(isPresented: $archivedDreamsShown) {
            NavigationStack {
                ArchivedDreams()
                    .padding(.horizontal)
                    .navigationTitle("Archived Dreams")
                    .toolbar {
                        CloseButtonToolbar("Close") {
                            archivedDreamsShown.toggle()
                        }
                    }
            }
        }
        .navigationTitle("My Dreams")
    }
    
    private func fetchDreams() async {
        await dreamFetcher.fetchUserDreams(userID: userID)
    }
    // FIX: Removed unused deleteDream(at:) function - deletion is handled inline in context menu
}

#Preview {
    NavigationStack {
        MyDreams()
    }
}
