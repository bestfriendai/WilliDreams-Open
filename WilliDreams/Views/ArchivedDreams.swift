//
//  ArchivedDreams.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/26/24.
//

import SwiftUI
import SwiftData
import WilliKit

struct ArchivedDreams: View {
    @Query(
        filter: #Predicate<Dream> {
            $0.isArchived == true
        },
        sort: \Dream.date,
        order: .reverse) private var dreams: [Dream]
    
    var body: some View {
        if dreams.isEmpty {
            ContentUnavailableView("No Archived Dreams", systemImage: "moon.stars.fill", description: Text("You have not archived any dreams yet."))
        } else {
            ScrollView {
                ForEach(dreams) { dream in
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(dream.date, style: .date)
                                    .font(.caption)
                                Spacer()
                                if dream.nightmareScale >= 0.9 {
                                    Text("Great")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                } else if dream.nightmareScale >= 0.6 {
                                    Text("Good")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                } else if dream.nightmareScale >= 0.4 {
                                    Text("Ok")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                } else if dream.nightmareScale >= 0.2 {
                                    Text("Bad")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                } else {
                                    Text("Nightmare")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                            Text(dream.name)
                                .font(.title)
                                .bold()
                            RoundedRectangle(cornerRadius: 20)
                                .frame(height: 1)
                                .foregroundStyle(.gray)
                            Text(dream.dreamDescription)
                            Spacer()
                        }
                        Spacer()
                    }
                    .williBackground()
                    .contextMenu {
                        Button(action: {
                            withAnimation {
                                dream.isArchived = false
                            }
                        }, label: {
                            Label("UnArchive", systemImage: "arrow.turn.up.right")
                        })
                    }
                }
                Rectangle()
                    .opacity(0)
                    .frame(height: 100)
            }
        }
    }
}
