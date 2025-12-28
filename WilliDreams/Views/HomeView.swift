//
//  HomeView.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/25/24.
//

import SwiftUI
import SwiftData
import WilliKit

struct HomeView: View {
    @AppStorage("aiSummary") private var aiSummary = ""
    @AppStorage("canAIProcess") private var canAIProcess = true
    @AppStorage("userUID") private var userID = ""
    
    @State private var dreamLoggerShown = false
    @Query private var dreams: [Dream]
    @State private var dreamsToShow: [Dream] = []
    
    @State private var dreamFetcher = DreamFetcher()
    
    var body: some View {
        ZStack {
            UIBackground()
            ScrollView {
                if canAIProcess {
                    VStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Label("My Weekly Summary", systemImage: "sparkles")
                                    .font(.caption)
                                Spacer()
                            }
                            Divider()
                            if aiSummary.isEmpty == false {
                                Text(aiSummary)
                            } else {
                                Text("Log a dream to see your AI Summary!")
                            }
                        }
                        .williBackground()
                    }
                    .padding(.horizontal)
                }
                
                VStack {
                    VStack {
                        HStack {
                            Label("Streak", systemImage: "flame.fill")
                                .font(.caption)
                            Spacer()
                        }
                        Divider()
                        HStack {
                            VStack(alignment: .leading) {
                                Label("\(getDreamStreak())", systemImage: "flame.fill")
                                    .multilineTextAlignment(.center)
                                    .font(.title)
                                    .bold()
                                    .contentTransition(.numericText())
                                HStack(spacing: 0) {
                                    Text("Start date: ")
                                    if let startDate = getStreakStartDate() {
                                        Text(startDate, style: .date)
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                    .williBackground()
                    .padding(.horizontal)
                }
                
                VStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Label("My Recent Dreams", systemImage: "clock")
                                .font(.caption)
                            Spacer()
                        }
                        Divider()
                        if dreamsToShow.isEmpty {
                            Text("You got no recent dreams.")
                        } else {
                            ForEach(dreamsToShow) { dream in
                                VStack {
                                    HStack {
                                        // FIX: Use getDreamStatus helper instead of magic numbers
                                        dreamStatusIcon(for: dream.nightmareScale)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 32)
                                        VStack(alignment: .leading) {
                                            Text(dream.name)
                                                .font(.title)
                                                .bold()
                                            Text(dream.dreamDescription)
                                                .lineLimit(2)
                                        }
                                        Spacer()
                                    }
                                    Divider()
                                }
                            }
                        }
                    }
                    .williBackground()
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            // FIX: Use prefix(5) instead of manual indexing for better performance
            dreamsToShow = Array(dreams.filter { $0.isArchived == false }.prefix(5))
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
#elseif os(macOS) || os(visionOS)
        .toolbar {
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
        }
#endif        
        .navigationTitle("Home")
        .task {
            print("WILLIDEBUG: Fetching dreams from Firebase...")
            dreamFetcher.syncAllDreamsToCloud(userID: userID)
            await dreamFetcher.fetchUserDreams(userID: userID)
            
            print("WILLIDEBUG: Listening for dream changes from Firebase...")
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
    }
    
    /// Returns the appropriate icon for a dream based on its nightmare scale
    private func dreamStatusIcon(for scale: Double) -> Image {
        switch getDreamStatus(dreamScale: scale) {
        case .great:
            return Image(systemName: "face.smiling.inverse")
        case .good:
            return Image(systemName: "hand.thumbsup.fill")
        case .ok:
            return Image(systemName: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill")
        case .bad:
            return Image(systemName: "hand.thumbsdown.fill")
        case .nightmare:
            return Image(systemName: "hand.raised.fill")
        }
    }

    func getDreamStreak() -> Int {
        let sortedDreams = dreams.sorted { $0.date > $1.date }
        // FIX: Use guard let instead of force unwrap
        guard let firstDream = sortedDreams.first else { return 0 }

        var streak = 1
        var previousDate = Calendar.current.startOfDay(for: firstDream.date)
        
        for dream in sortedDreams.dropFirst() {
            let currentDate = Calendar.current.startOfDay(for: dream.date)
            let difference = Calendar.current.dateComponents([.day], from: currentDate, to: previousDate).day ?? 0
            
            if difference == 1 {
                streak += 1
                previousDate = currentDate
            } else if difference > 1 {
                break
            }
        }
        
        return streak
    }
    
    private func getStreakStartDate() -> Date? {
        let sortedDreams = dreams.sorted { $0.date > $1.date }
        guard let firstDream = sortedDreams.first else { return nil }

        var previousDate = Calendar.current.startOfDay(for: firstDream.date)
        var startDate = firstDream.date

        for dream in sortedDreams.dropFirst() {
            let currentDate = Calendar.current.startOfDay(for: dream.date)
            let difference = Calendar.current.dateComponents([.day], from: currentDate, to: previousDate).day ?? 0

            if difference == 1 {
                previousDate = currentDate
                startDate = dream.date
            } else if difference > 1 {
                break
            }
        }

        return startDate
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
