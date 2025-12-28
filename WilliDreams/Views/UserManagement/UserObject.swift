//
//  UserObject.swift
//  WilliStudy
//
//  Created by William Gallegos on 2/24/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage
import SwiftUI
import FirebaseAuth

struct User: Identifiable, Codable, @unchecked Sendable {
    @DocumentID var id: String?
    var username: String
    var userEmail: String
    var userUID: String
    var userDescription: String?
    var pfp: URL? = nil
    var streak: Int? = 0
    var score: Int? = 0
    var timeSinceLastStreak: Int? = 0
    var friends: [String]? = []
    var friendRequestsReceived: [String]? = []
    var usersBlocked: [String]? = []
    var appsUsed: [String]? = []
    var phoneNumber: String?
    var countryCode: String?
    var creationDate: Date?
    
    init(id: String? = nil, username: String, userEmail: String, userUID: String) {
        self.username = username
        self.userEmail = userEmail
        self.userUID = userUID
    }
}

func fetchUser(userUID: String) async throws -> User? {
    if userUID.isEmpty == true { return nil }
    let userRef = Firestore.firestore().collection("Users").document(userUID)
    let documentSnapshot = try await userRef.getDocument()
    if documentSnapshot.exists {
        do {
            let user = try documentSnapshot.data(as: User.self)
            print("WILLIDEBUG: Successfully fetched user data for \(userUID)")
            return user
        } catch {
            print("WILLIDEBUG: Failed to decode user data for \(userUID), \(error.localizedDescription)")
            return nil
        }
    } else {
        print("WILLIDEBUG: Document for userID \(userUID) does not exist.")
        return nil
    }
}

func fetchCurrentUser() async throws -> User? {
    guard let currentUser = Auth.auth().currentUser else { return nil }
    let userID = currentUser.uid
    let userCollection = Firestore.firestore().collection("Users")
    let userDocument = userCollection.document(userID)
    
    var user = try await userDocument.getDocument(as: User.self)
    
    if user.appsUsed?.contains("WilliDreams") == false {
        user.appsUsed = (user.appsUsed ?? []) + ["WilliDreams"]
        
        Task {
            try await userDocument.updateData([
                "appsUsed": FieldValue.arrayUnion(["WilliDreams"])
            ])
        }
    }
    
    if user.creationDate == nil, let creationDate = currentUser.metadata.creationDate {
        user.creationDate = creationDate
        
        Task {
            try await userDocument.updateData([
                "creationDate": Timestamp(date: creationDate)
            ])
        }
    }
    
    return user
}


// MARK: Profile Picture

func getDefaultPFP() -> Data {
    let defaultImage = defaultPFPs().randomElement() ?? "Placeholder"
    var data: Data = Data()
    #if os(macOS)
    // FIX: Use variable `defaultImage` instead of hardcoded string "defaultImage"
    if let image = NSImage(named: defaultImage) {
        if let tiffData = image.tiffRepresentation,
           let bitmapImageRep = NSBitmapImageRep(data: tiffData) {
            let jpegData = bitmapImageRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
            data = jpegData ?? Data()
        }
    }
    #else
    data = UIImage(named: defaultImage)?.jpegData(compressionQuality: 0.7) ?? Data()
    #endif
    return data
}

func getUser(username: String) async -> User? {
    
    do {
        let querySnapshot = try await Firestore.firestore().collection("Users")
            .whereField("username", isEqualTo: username)
            .getDocuments()
        
        // Check for document existence
        guard let documents = querySnapshot.documents.first else {
            return nil // No user found with that username
        }
        
        // Decode the first document (assuming unique username)
        return try documents.data(as: User.self)
        
    } catch {
        print("WILLIDEBUG: \(error.localizedDescription)")
        // Consider returning a specific error value or throwing a custom error
        return nil
    }
}

// FIX: Use direct document fetch instead of query since userUID is the document ID
func getUser(userID: String) async -> User? {
    guard !userID.isEmpty else { return nil }

    do {
        // Directly fetch by document ID (more efficient than query)
        let documentSnapshot = try await Firestore.firestore()
            .collection("Users")
            .document(userID)
            .getDocument()

        guard documentSnapshot.exists else {
            return nil // No user found with that ID
        }

        return try documentSnapshot.data(as: User.self)
    } catch {
        print("WILLIDEBUG: \(error.localizedDescription)")
        return nil
    }
}

func defaultPFPs() -> [String] {
    ["Cat", "Dog", "Elephant", "Lion", "Penguin", "Sloth"]
}

func updateUserProfilePicture(imageUrl: String, userID: String) {
    let db = Firestore.firestore()
    let userRef = db.collection("Users").document(userID)
    userRef.updateData(["pfp": imageUrl]) { error in
        if let error = error {
            print("WILLIDEBUG: Error updating user profile: \(error.localizedDescription)")
        }
        // FIX: Removed empty else block
    }
}

func compressImage(data: Data) -> Data {
#if os(macOS)
    let image = NSImage(data: data)
    if let imageData = image?.tiffRepresentation {
        if let bitmap = NSBitmapImageRep(data: imageData) {
            let compressionFactor: CGFloat = 0.5 // Adjust compression as needed (0.0 - 1.0)
            if let compressedData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionFactor]) {
                return compressedData
            }
        }
    }
#else
    let image = UIImage(data: data)
    if let compressedData = image?.jpegData(compressionQuality: 0.5) { // Adjust quality as needed (0.0 - 1.0)
        return compressedData
    }
#endif
    // Handle case where compression fails (return original data or handle error)
    return data
}

// Function to upload image to Firebase Storage
func uploadProfilePicture(data: Data, userID: String, completion: @escaping (String?, Error?) -> Void) {
    let storage = Storage.storage()
    
    let storageRef = storage.reference().child("user-profile-pictures/\(userID).jpg")
    storageRef.putData(data, metadata: nil) { (metadata, error) in
        if let error = error {
            completion(nil, error)
        } else {
            // Get download URL using StorageReference
            storageRef.downloadURL(completion: { (url, error) in
                if let error = error {
                    completion(nil, error) // Handle error getting download URL
                } else if let url = url {
                    completion(url.absoluteString, nil) // Success, return URL string
                } else {
                    completion(nil,  // Handle case where URL is nil (unlikely but possible)
                               NSError(domain: "MyErrorDomain", code: 1, userInfo: ["message": "Failed to get download URL"]))
                }
            })
        }
    }
}
