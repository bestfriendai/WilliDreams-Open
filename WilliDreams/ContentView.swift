//
//  ContentView.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/18/24.
//

import SwiftUI

@Observable
@MainActor
class NavigationHandler {
    static let shared = NavigationHandler()
    
    var path = NavigationPath()
}

struct ContentView: View {
    @State private var currentView = "Home"
    
    @State private var navigationHandler = NavigationHandler.shared
    
    var body: some View {
        if #available(iOS 18, macOS 15, *) {
            TabView {
                Tab("Home", systemImage: "house.fill") {
                    NavigationStack(path: $navigationHandler.path.animation(.interpolatingSpring)) {
                        HomeView()
                    }
                }
                
                Tab("My Dreams", systemImage: "moon.stars") {
                    NavigationStack(path: $navigationHandler.path.animation(.interpolatingSpring)) {
                        MyDreams()
                    }
                }
                
                Tab("Friends", systemImage: "person.2.fill") {
                    NavigationStack(path: $navigationHandler.path.animation(.interpolatingSpring)) {
                        FriendsDreamsScroller()
                    }
                }

                Tab("Settings", systemImage: "gearshape.fill") {
                    NavigationStack(path: $navigationHandler.path.animation(.interpolatingSpring)) {
                        SettingsContent()
                    }
                }
            }
            .tabViewStyle(.sidebarAdaptable)
        } else {
            #if os(iOS)
            TabView {
                NavigationStack {
                    HomeView()
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                
                NavigationStack {
                    MyDreams()
                }
                .tabItem {
                    Label("My Dreams", systemImage: "moon.stars")
                }
                
                NavigationStack {
                    FriendsDreamsScroller()
                }
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
                
                NavigationStack {
                    SettingsContent()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
            #else
            VStack {
                switch currentView {
                case "Home":
                    NavigationStack(path: $navigationHandler.path.animation(.interpolatingSpring)) {
                        HomeView()
                    }
                case "MyDreams":
                    NavigationStack(path: $navigationHandler.path.animation(.interpolatingSpring)) {
                        MyDreams()
                    }
                case "Friends":
                    NavigationStack(path: $navigationHandler.path.animation(.interpolatingSpring)) {
                        // FIX: Use FriendsDreamsScroller instead of incomplete DreamRootView
                        FriendsDreamsScroller()
                    }
                case "Settings":
                    NavigationStack(path: $navigationHandler.path.animation(.interpolatingSpring)) {
                        SettingsContent()
                    }
                default:
                    Text("Unsupported")
                }
            }
            .toolbar {
                ToolbarItem(id: "TabBar", placement: .navigation) {
                    Picker("", selection: $currentView) {
                        Text("Home")
                            .tag("Home")
                        Text("My Dreams")
                            .tag("MyDreams")
                        Text("Friends")
                            .tag("Friends")
                        Text("Settings")
                            .tag("Settings")
                    }
                    .pickerStyle(.inline)
                }
            }
            #endif
        }
    }
}

#Preview {
    ContentView()
}
