//
//  FriendDream.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/30/24.
//

import Foundation
import FirebaseFirestore
import SwiftUI
import FirebaseStorage
import Firebase

final class DreamCloud: Identifiable, Codable, @unchecked Sendable {
    @DocumentID var id: String?
    var uuid: String
    var name: String
    var date: Date
    var dreamDescription: String
    var nightmareScale: Double
    var author: String
    var likedBy: [String]?
    
    var isArchived: Bool
    var titleVisible: Bool
    var createdAt: Timestamp
    var updatedAt: Timestamp
    var sharedWith: [String]?
    var isPublic: Bool
    var deleted: Bool

    init(dream: Dream, userID: String) {
        self.id = dream.id
        self.uuid = dream.id
        self.name = dream.name
        self.date = dream.date
        self.dreamDescription = dream.dreamDescription
        self.nightmareScale = dream.nightmareScale
        self.author = userID
        self.isArchived = dream.isArchived
        self.titleVisible = dream.titleVisible
        self.createdAt = Timestamp(date: dream.date)
        self.updatedAt = Timestamp(date: Date())
        self.sharedWith = []
        self.isPublic = dream.isPublic
        self.deleted = false
    }
}
