//
//  LoadingOverlayView.swift
//  WilliStudy
//
//  Created by William Gallegos on 1/14/25.
//

import SwiftUI

struct LoadingOverlayView: View {
    @Binding var isShowing: Bool
    @State private var verticalOffset: CGFloat = 0
    var isForNetwork = true

    var body: some View {
        if isShowing {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                    .opacity(0.2)
                
                WilliLoadingIndicator(isForNetwork: isForNetwork)
            }
            .transition(.opacity)
            .animation(.easeInOut, value: isShowing)
        }
    }
    
    private func startBouncingAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
        ) {
            verticalOffset = -20 // Moves up
        }
    }
}

#Preview {
    LoadingOverlayView(isShowing: .constant(true))
}

struct WilliLoadingIndicator: View {
    @State private var verticalOffset: CGFloat = 0
    @State private var showError = false
    var isForNetwork = false
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("BackgroundColor"))
                .frame(width: 60, height: 60)
                .overlay {
                    Image("LaunchIcon")
                        .resizable()
                        .scaledToFit()
                }
                .offset(y: 20)
                .offset(y: verticalOffset)
                .onAppear {
                    startBouncingAnimation()
                    checkForError()
                }
                .onDisappear {
                    verticalOffset = 0
                }
            
            if isForNetwork && showError {
                Text("")
                    .alert("Account Network Error", isPresented: $showError, actions: {}, message: {Text("Error connecting to the network... Check your internet. If your internet is fine, go to Settings > 'Fix Account Issues'")})
            }
        }
    }
    
    private func startBouncingAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
        ) {
            verticalOffset = -20 // Moves up
        }
    }
    
    private func checkForError() {
        if isForNetwork {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                showError = true
            }
        }
    }
}
