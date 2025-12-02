//
//  DreamModel.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/18/24.
//

import Foundation
import SwiftData
import FirebaseFirestore

@Model
final class Dream {
    var id: String = UUID().uuidString
    var name: String = ""
    var date: Date = Date()
    var dreamDescription: String = "Description"
    var nightmareScale: Double = 0
    var isArchived: Bool = false
    var titleVisible: Bool = true
    var isPublic: Bool = true
    
    init(name: String) {
        self.name = name
        self.date = Date()
    }
}
