//
//  SDLoadingView.swift
//  WilliStudy
//
//  Created by William Gallegos on 5/7/24.
//

import SwiftUI

struct SDLoadingView: View {
    @State private var yOffset: CGFloat = 0
    @State private var isGoingUp = true
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                RoundedRectangle(cornerRadius: 15)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Triangle()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
            }
            .offset(y: yOffset)
        }
        .onAppear {
            animateSquare()
        }
    }
    
    func animateSquare() {
        withAnimation(.linear(duration: 0.2)) {
            yOffset = -100
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.linear(duration: 0.2)) {
                yOffset = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateSquare()
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    SDLoadingView()
}
