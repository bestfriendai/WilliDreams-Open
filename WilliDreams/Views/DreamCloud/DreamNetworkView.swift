//
//  DreamNetworkView.swift
//  WilliDreams
//
//  Created by William Gallegos on 3/8/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import WilliKit

struct DreamNetworkView: View {
    @State var dream: DreamCloud
    
    @AppStorage("loginStatus") private var isLoggedIn = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("userUID") private var userID = ""
        
    @State private var reportScreenShown = false
    
    @State private var docListener: ListenerRegistration?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                
                ProfileNavigationLink(dream: dream)
                Spacer()
                switch getDreamStatus(dreamScale: dream.nightmareScale) {
                case .great:
                    Text("Great")
                        .font(.caption)
                        .foregroundStyle(.green)
                case .good:
                    Text("Good")
                        .font(.caption)
                        .foregroundStyle(.green)
                case .ok:
                    Text("Ok")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                case .bad:
                    Text("Bad")
                        .font(.caption)
                        .foregroundStyle(.red)
                case .nightmare:
                    Text("Nightmare")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Divider()
            Text(dream.dreamDescription)
                .multilineTextAlignment(.leading)
            Divider()
            HStack {
                Button(action: {
                    Task {
                        guard let dreamID = dream.id else {return}
                        if dream.likedBy == nil {
                            dream.likedBy = []
                        }
                        
                        if let likedByArray = dream.likedBy {
                            if likedByArray.contains(userID) {
                                Firestore.firestore().collection("UserDreams").document(dream.author).collection("dreams").document(dreamID).updateData([
                                    "likedBy": FieldValue.arrayRemove([userID])
                                ])
                            } else {
                                Firestore.firestore().collection("UserDreams").document(dream.author).collection("dreams").document(dreamID).updateData([
                                    "likedBy": FieldValue.arrayUnion([userID])
                                ])
                            }
                        }
                    }
                }, label: {
                    HStack {
                        Image(systemName: "heart")
                            .symbolVariant((dream.likedBy?.contains(userID) ?? false) ? .fill : .none)
                            .symbolEffect(.bounce, value: (dream.likedBy?.contains(userID) ?? false))
                        if getPlatform() == .iPhone {
                            Text("\(dream.likedBy?.count ?? 0)")
                        } else {
                            if (dream.likedBy?.isEmpty ?? true) {
                                Text("Like")
                                    .contentTransition(.interpolate)
                            } else {
                                Text("^[\(dream.likedBy?.count ?? 0) Like](inflect: true)")
                                    .contentTransition(.numericText(value: Double(dream.likedBy?.count ?? 0)))
                            }
                        }
                    }
                    .padding(5)
                    .background {
                        RoundedRectangle(cornerRadius: 90)
                            .foregroundStyle(.gray)
                            .opacity(0.3)
                    }
                })
                .font(.title3)
                .buttonStyle(.borderless)
                .foregroundStyle(.primary)
                .withHoverEffect()
                
                Spacer()
                
                Text(dream.date, style: .date)
                
                Image(systemName: "exclamationmark.bubble")
                    .foregroundStyle(.primary)
                    .onTapGesture {
                        reportScreenShown = true
                    }
            }
        }
        .padding(.all, 20)
        .background {
            Color.gray
                .opacity(0.2)
                .clipShape(.rect(cornerRadius: 20))
                .padding(.all, 9)
        }
        .onAppear {
            if docListener == nil {
                docListener = Firestore.firestore().collection("UserDreams").document(dream.author).collection("dreams").document(dream.id ?? "").addSnapshotListener({ snapshot, error in
                    if let snapshot {
                        if snapshot.exists {
                            print("WILLIDEBUG: Document exists")
                            if let updatedPost = try? snapshot.data(as: DreamCloud.self) {
                                withAnimation {
                                    dream = updatedPost
                                    print("WILLIDEBUG: Attempted to update")
                                }
                            }
                        } else {
                            print("WILLIDEBUG: Document does not exist")
                        }
                    }
                    
                    if let error = error {
                        print("WILLIDEBUG: Firestore error: \(error.localizedDescription)")
                    }
                })
            }
        }
        .sheet(isPresented: $reportScreenShown) {
            NavigationStack {
                DreamReport(dream: dream)
            }
        }
    }
}
