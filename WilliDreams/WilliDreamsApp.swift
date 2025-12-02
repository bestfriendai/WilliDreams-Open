//
//  WilliDreamsApp.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/18/24.
//

import SwiftUI
import SwiftData
import Firebase

@main
struct WilliDreamsApp: App {
    @AppStorage("isGuest") private var isGuest = false
    @AppStorage("loginStatus") private var isLoggedIn = false
    @AppStorage("userUID") private var userID = ""
    
    init() {
        FirebaseApp.configure()
    }
    
#if os(macOS)
    @State private var aboutWindow: NSWindow?
#endif
    
    @State private var navigationHandler = NavigationHandler.shared
    
    @AppStorage("isBanned", store: UserDefaults(suiteName: "group.com.WilliamGallegos.SharedSettings")) private var isBanned = false

    var body: some Scene {
        WindowGroup {
            if MTLCreateSystemDefaultDevice() != nil {
                if isBanned {
                    BanView()
                        .task {
                            await isBanned = getIsBanned(userId: userID)
                        }
                } else if isLoggedIn || isGuest {
                    ContentView()
                        .task {
                            await isBanned = getIsBanned(userId: userID)
                        }
                } else {
                    FirstStartup(isGuest: $isGuest)
                }
            } else {
#if os(macOS)
                Text("")
                    .alert("Unsupported Device", isPresented: .constant(true), actions: {
                        Button("Close App") {
                            NSApplication.shared.terminate(nil)
                        }
                    }, message: {
                        Text("WilliDreams is not supported on devices without a Metal GPU.")
                    })
#endif
            }
        }
        .modelContainer(createModelContainer())
        #if os(macOS)
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
        #endif
        .commands {
#if os(macOS)
            CommandGroup(replacing: .appInfo) {
                Button("About WilliDreams") {
                    if aboutWindow == nil {
                        let aboutView = NavigationStack { AboutApp() }
                        aboutWindow = NSWindow(
                            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
                            styleMask: [.titled, .closable],
                            backing: .buffered,
                            defer: false
                        )
                        aboutWindow?.contentView = NSHostingView(rootView: aboutView)
                        aboutWindow?.center()
                        aboutWindow?.title = "About WilliDreams"
                        aboutWindow?.makeKeyAndOrderFront(nil)
                        aboutWindow?.isReleasedWhenClosed = false
                    } else {
                        aboutWindow?.makeKeyAndOrderFront(nil)
                    }
                }
            }
#endif
        }
#if os(macOS)
        Settings {
            NavigationStack(path: $navigationHandler.path.animation(.interpolatingSpring)) {
                SettingsContent()
            }
        }
#endif
    }
}

func createModelContainer() -> ModelContainer {
    // Local schema

    // Combined schema that includes both cloud and local models
    let schema = Schema([
        Dream.self
    ])
    
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, groupContainer: .identifier("group.com.WilliamGallegos.WilliDreams.Shared"))

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}

func isSixAMOnMarch24InMST(date: Date) -> Bool {
    let timeZone = TimeZone(abbreviation: "MST")
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone!

    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)

    if components.month == 3 &&
       components.day == 24 &&
       components.hour == 6 &&
       components.minute == 0 {
        return true
    } else {
        return false
    }
}
