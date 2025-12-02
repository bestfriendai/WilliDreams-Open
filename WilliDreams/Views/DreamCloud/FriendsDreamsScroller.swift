//
//  FriendsDreamsView.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/30/24.
//

import SwiftUI
import SwiftData
import WilliKit

struct FriendsDreamsScroller: View {
    @AppStorage("loginStatus") private var isLoggedIn = false

    @State private var content: [DreamCloud] = []
    @State private var isFetching = false
    
    var body: some View {
        ZStack {
            UIBackground()
            if isLoggedIn {
                FriendDreamListView(dreams: $content)
            } else {
                VStack {
                    Text("Sign in to see your friend's dreams!")
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.center)
                    Text("WilliDreams can let you share your dreams with your friends and family.")
                        .multilineTextAlignment(.center)
                    VStack {
                        NavigationLink(destination: LoginView()) {
                            Text("Sign In")
                                .font(.largeTitle)
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
#if !os(visionOS)
                        .buttonStyle(WillButtonStyle())
#endif
                        
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign Up")
                                .font(.largeTitle)
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
#if !os(visionOS)
                        .buttonStyle(WillButtonStyle())
#endif
                    }
                }
                .frame(maxHeight: .infinity)
                .padding()
            }
        }
    }
}
