//
//  AppContent.swift
//  WilliWidgets
//
//  Created by William Gallegos on 29.10.2025.
//

import SwiftUI

struct AppUserContent: View {
    @State private var dreams: [DreamCloud] = []
    @State private var dreamFetcher = DreamFetcher()
    
    
    @State var userToShow: User
    
    var body: some View {
        VStack {
            HStack {
                Text("Public Dreams:")
                    .font(.body)
                    .underline()
                    .multilineTextAlignment(.leading)
                    .padding(.leading)
                Spacer()
            }
            VStack {
                ForEach(dreams) { dream in
                    DreamNetworkView(dream: dream)
                }
            }
        }
        .task {
            dreams = await dreamFetcher.fetchUserDreams(userID: userToShow.userUID, shouldMerge: false).filter({$0.isArchived == false})
        }
    }
}
