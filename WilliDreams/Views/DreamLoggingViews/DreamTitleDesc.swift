//
//  DreamTitleDesc.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/26/24.
//

import SwiftUI

struct DreamTitleDesc: View {
    @Binding var dreamTitle: String
    @Binding var dreamDescription: String
    @Binding var dreamViewState: Int
    @Binding var shouldShowTitle: Bool
    @Binding var friendsCanSee: Bool
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                if shouldShowTitle {
                    TextField("Title", text: $dreamTitle)
                        .textFieldStyle(.plain)
                    //.textFieldStyle(WillTextFieldStyle())
                    Divider()
                }
                TextField("Description", text: $dreamDescription, axis: .vertical)
                    .textFieldStyle(.plain)
                Spacer()
                #if os(iOS)
                if #available(iOS 26, *) {
                    Button(action: {
                        withAnimation(.interpolatingSpring) {
                            dreamViewState += 1
                        }
                    }, label: {
                        Text("Log")
                            .bold()
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, maxHeight: 35)
                    })
                    .buttonStyle(.glassProminent)
                    .padding()
                } else {
                    Button(action: {
                        withAnimation(.interpolatingSpring) {
                            dreamViewState += 1
                        }
                    }, label: {
                        Text("Log")
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
                
                Toggle(isOn: $friendsCanSee) {
                    Text("Friends can see this dream")
                }
            }
            .padding()
        }
        .navigationTitle("Write about your dream")
        #if os(macOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Log") {
                    withAnimation(.interpolatingSpring) {
                        dreamViewState += 1
                    }
                }
            }
        }
        #endif
    }
}
