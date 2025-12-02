//
//  DreamSlider.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/25/24.
//

import SwiftUI

struct DreamSlider: View {
    @Binding var dreamLogViewState: Int
    @Binding var nightmareScale: Double
    
    @State private var image: String = "face.smiling.inverse"
    
    var body: some View {
        VStack {
            Text("How was your dream last night?")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            Spacer()
            VStack {
                if #available(iOS 18, macOS 15, *) {
                    Image(systemName: image)
                        .modifierIf(nightmareScale >= 0.6) { element in
                            element
                                .foregroundStyle(.green)
                        }
                        .modifierIf(nightmareScale >= 0.4) { element in
                            element
                                .foregroundStyle(.yellow)
                        }
                        .modifierIf(nightmareScale < 0.4 && nightmareScale >= 0) { element in
                            element
                                .foregroundStyle(.red)
                        }
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .replace.downUp)))
                } else {
                    Image(systemName: image)
                        .modifierIf(nightmareScale >= 0.6) { element in
                            element
                                .foregroundStyle(.green)
                        }
                        .modifierIf(nightmareScale >= 0.4) { element in
                            element
                                .foregroundStyle(.yellow)
                        }
                        .modifierIf(nightmareScale < 0.4 && nightmareScale >= 0) { element in
                            element
                                .foregroundStyle(.red)
                        }
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .onChange(of: nightmareScale) {
                withAnimation {
                    if nightmareScale >= 0.9 {
                        image = "face.smiling.inverse"
                    } else if nightmareScale >= 0.6 {
                        image = "hand.thumbsup.fill"
                    } else if nightmareScale >= 0.4 {
                        image = "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill"
                    } else if nightmareScale >= 0.2 {
                        image = "hand.thumbsdown.fill"
                    } else {
                        image = "hand.raised.fill"
                    }
                }
            }
            #if os(iOS)
            .font(.system(size: 200))
            #elseif os(macOS)
            .font(.system(size: 100))
            #endif
            Spacer()
            VStack {
                if nightmareScale >= 0.9 {
                    Text("Great")
                        .foregroundStyle(.green)
                } else if nightmareScale >= 0.6 {
                    Text("Good")
                        .foregroundStyle(.green)
                } else if nightmareScale >= 0.4 {
                    Text("Ok")
                        .foregroundStyle(.yellow)
                } else if nightmareScale >= 0.2 {
                    Text("Bad")
                        .foregroundStyle(.red)
                } else {
                    Text("Nightmare")
                        .foregroundStyle(.red)
                }
            }
            .font(.largeTitle)
            .bold()
            if #available(iOS 26, *) {
                Slider(value: $nightmareScale.animation())
                    .padding(.horizontal)
            } else {
                WillSlider(value: $nightmareScale.animation())
                    .padding(.horizontal)
            }
            HStack {
                Text("Nightmare")
                Spacer()
                Text("Pleasant")
            }
            .padding(.horizontal)
            
            #if os(iOS)
            if #available(iOS 26, *) {
                Button(action: {
                    withAnimation(.interpolatingSpring) {
                        dreamLogViewState += 1
                    }
                }, label: {
                    Text("Next")
                        .bold()
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: 35)
                })
                .buttonStyle(.glassProminent)
                .padding(.horizontal)
            } else {
                Button(action: {
                    withAnimation(.interpolatingSpring) {
                        dreamLogViewState += 1
                    }
                }, label: {
                    Text("Next")
                        .bold()
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: 50)
                })
                .background {
                    RoundedRectangle(cornerRadius: 90)
                        .foregroundStyle(Color.accentColor)
                }
                .padding()
            }
            #endif
        }
        #if os(macOS)
        .padding()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Next") {
                    withAnimation(.interpolatingSpring) {
                        dreamLogViewState += 1
                    }
                }
            }
        }
        #endif
    }
}

#Preview {
    @Previewable @State var nightmareScale: Double = 1
    @Previewable @State var dreamLogView: Int = 1
    
    DreamSlider(dreamLogViewState: $dreamLogView, nightmareScale: $nightmareScale)
}


struct WillSlider: View {
    @Binding var value: Double
    
    @State var lastCoordinateValue: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 90)
                .foregroundStyle(.gray)
            HStack {
                Slider(value: $value)
                    .tint(.gray)
                    .padding(.horizontal, 3)
            }
        }
        .frame(height: 30)
    }
}
