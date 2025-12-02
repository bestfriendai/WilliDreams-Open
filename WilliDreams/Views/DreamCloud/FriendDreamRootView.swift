//
//  FriendDreamRootView.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/30/24.
//

import SwiftUI

struct DreamRootView: View {
    @State private var isShowingUploadScreen = false
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .foregroundStyle(Color.window)
                .ignoresSafeArea()
            ContentUnavailableView("Coming Soon", systemImage: "moon.stars.fill", description: Text("Sharing with your friends is currently not available and will be ready in a future beta."))
            //FriendsDreamsScroller()
        }
        /*
        .overlay {
#if os(iOS)
            VStack {
                Spacer()
                Button(action: {
                    isShowingUploadScreen = true
                }, label: {
                    Label("Upload", systemImage: "square.and.arrow.up")
                        .foregroundStyle(.white)
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 90)
                        }
                })
                .padding(.bottom)
            }
#endif
        }
         */
        .navigationTitle("Friends Dreams")
        .sheet(isPresented: $isShowingUploadScreen) {
            NavigationStack {
                //UploadView()
            }
        }
    }
}
