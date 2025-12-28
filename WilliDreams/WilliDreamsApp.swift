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
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.yellow)
                    Text("Unsupported Device")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("WilliDreams requires a Metal-compatible GPU to run.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Close App") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    let schema = Schema([
        Dream.self
    ])

    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        groupContainer: .identifier("group.com.WilliamGallegos.WilliDreams.Shared")
    )

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        // Log the error for debugging before crashing
        print("WILLIDEBUG: CRITICAL - Could not create ModelContainer: \(error.localizedDescription)")
        // The app cannot function without persistent storage, so this is a fatal condition
        fatalError("Could not create ModelContainer: \(error)")
    }
}
