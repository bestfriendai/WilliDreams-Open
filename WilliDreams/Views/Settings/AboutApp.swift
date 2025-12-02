//
//  AboutApp.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/25/24.
//

import SwiftUI
import Foundation
import WilliKit

struct AboutApp: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Form {
            VStack(alignment: .leading) {
                HStack {
                    Image("LaunchIcon")
                        .resizable()
                        .frame(maxWidth: 100, maxHeight: 100)
                }
                Text("WilliDreams")
                    .font(.title)
                    .bold()
                Text("WilliDreams is an app made by a solo developer.")
            }
            .williFormElement(colorScheme: colorScheme)

            Section("Version") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("\(Bundle.release)")
                        .foregroundStyle(.gray)
                }
                HStack {
                    Text("Build number")
                    Spacer()
                    Text("\(Bundle.build)")
                        .foregroundStyle(.gray)
                }
            }
            .williFormElement(colorScheme: colorScheme)

            /*
            if isSixAMOnMarch24InMST(date: Date.now) {
                Section("Buy me a Coffee") {
                    Link(destination: URL(string: "https://buymeacoffee.com/williapple")!) {
                        HStack {
                            Label("Make a Donation", systemImage: "dollarsign")
                            Spacer()
                        }
                    }
                }
                .williFormElement(colorScheme: colorScheme)
            }
             */
            
            Section("Social Media") {
                Link(destination: URL(string: "https://www.instagram.com/willidreamsapp/")!, label: {
                    Label("Follow on Instagram", systemImage: "camera.fill")
                        .foregroundStyle(.textColorSet)
                })
                Link(destination: URL(string: "https://testflight.apple.com/join/gR64pNs9")!, label: {
                    Label("Become a beta tester", systemImage: "bolt.fill")
                        .foregroundStyle(Color("TextColorSet"))
                })
            }
            .williFormElement(colorScheme: colorScheme)

            
            Text("\(Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? "")")
                .williFormElement(colorScheme: colorScheme)

        }
        .formStyle(.grouped)
        .williFormBackground(colorScheme: colorScheme)
        .navigationTitle("About")
    }
}

#Preview {
    AboutApp()
}

protocol ApplicationVersionInfo {
    static var release: String { get }
    static var build: String { get }
    static var version: String { get }
    static var isAppStoreBuild: Bool { get }
}

extension ApplicationVersionInfo {
    static var version: String {
        return "\(release).\(build)"
    }
    
    static var build: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String? ?? "x"
    }
}

extension Bundle: ApplicationVersionInfo {
    static var release: String {
        return main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "x.x"
    }

    static var build: String {
        return main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "x"
    }

    static var version: String {
        return "\(release).\(build)"
    }
    
    static var isAppStoreBuild: Bool {
        #if APP_STORE
        return true
        #else
        return false
        #endif
    }
}
