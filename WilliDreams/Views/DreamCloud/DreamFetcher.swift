//
//  DreamFetcher.swift
//  WilliDreams
//
//  Created by William Gallegos on 2/20/25.
//

import SwiftData
import FirebaseFirestore
import FirebaseCore

struct DreamFetcher: @unchecked Sendable {
    private let db = Firestore.firestore()

    /// Fetches user dreams from Firestore and merges them with SwiftData.
    func fetchUserDreams(userID: String, shouldMerge: Bool = true) async -> [DreamCloud] {
        if userID.isEmpty == false {
            let dreamsCollection = db.collection("UserDreams")
                .document(userID)
                .collection("dreams")
            
            do {
                let snapshot = try await dreamsCollection
                    .whereField("deleted", isEqualTo: false)
                    .order(by: "createdAt", descending: true)
                    .getDocuments()
                
                let cloudDreams: [DreamCloud] = snapshot.documents.compactMap { document in
                    do {
                        return try document.data(as: DreamCloud.self)
                    } catch {
                        print("Failed to decode document \(document.documentID): \(error)")
                        return nil
                    }
                }
                
                if shouldMerge {
                    mergeDreamsWithSwiftData(cloudDreams)
                }
                
                return cloudDreams
            } catch {
                print("Error fetching dreams: \(error.localizedDescription)")
                return []
            }
        } else {
            return []
        }
    }

    /// Merges Firestore dreams into SwiftData.
    private func mergeDreamsWithSwiftData(_ cloudDreams: [DreamCloud]) {
        let context = ModelContext(createModelContainer())
        
        for cloudDream in cloudDreams {
            if let existingDream = fetchLocalDream(byUUID: cloudDream.uuid, in: context) {
                // Update existing dream
                existingDream.name = cloudDream.name
                existingDream.date = cloudDream.date
                existingDream.dreamDescription = cloudDream.dreamDescription
                existingDream.nightmareScale = cloudDream.nightmareScale
                existingDream.isArchived = cloudDream.isArchived
            } else {
                // Insert new dream
                let newDream = Dream(name: cloudDream.name)
                newDream.id = cloudDream.uuid
                newDream.date = cloudDream.date
                newDream.dreamDescription = cloudDream.dreamDescription
                newDream.nightmareScale = cloudDream.nightmareScale
                newDream.isArchived = cloudDream.isArchived
                context.insert(newDream)
            }
        }

        do {
            try context.save()
        } catch {
            print("Error saving dreams to local context: \(error)")
        }
    }

    /// Fetches a local dream from SwiftData by its UUID.
    private func fetchLocalDream(byUUID uuid: String, in context: ModelContext) -> Dream? {
        let fetchDescriptor = FetchDescriptor<Dream>(predicate: #Predicate { $0.id == uuid })
        do {
            return try context.fetch(fetchDescriptor).first
        } catch {
            print("Error fetching local dream with UUID \(uuid): \(error)")
            return nil
        }
    }

    /// Syncs a single dream to Firestore, ensuring no duplicates.
    func syncDreamToCloud(dream: Dream, userID: String) {
        let dreamCloud = DreamCloud(dream: dream, userID: userID)
        uploadDreamToCloud(dreamCloud: dreamCloud, userID: userID)
    }

    /// Syncs all local dreams to Firestore.
    func syncAllDreamsToCloud(userID: String) {
        let context = ModelContext(createModelContainer())
        let fetchDescriptor = FetchDescriptor<Dream>()
        
        do {
            let localDreams = try context.fetch(fetchDescriptor)
            for dream in localDreams {
                let dreamCloud = DreamCloud(dream: dream, userID: userID)
                uploadDreamToCloud(dreamCloud: dreamCloud, userID: userID)
            }
        } catch {
            print("Error fetching local dreams: \(error)")
        }
    }
    
    /// Deletes a dream from Firestore.
    func deleteDreamFromCloud(dream: Dream, userID: String) {
        let dreamsCollection = db.collection("UserDreams")
            .document(userID)
            .collection("dreams")

        dreamsCollection.whereField("uuid", isEqualTo: dream.id).getDocuments { snapshot, error in
            if let error = error {
                print("Error finding dream to update: \(error.localizedDescription)")
                return
            }

            for document in snapshot?.documents ?? [] {
                document.reference.updateData(["deleted": true, "updatedAt": Timestamp(date: Date())]) { error in
                    if let error = error {
                        print("Error marking dream as deleted: \(error.localizedDescription)")
                    } else {
                        print("Dream successfully marked as deleted!")
                    }
                }
            }
        }
    }
    
    /// Fetches friends' dreams from Firestore for a given date.
    func fetchFriendsDreams(date: Date = Date()) async throws -> [DreamCloud] {
        guard let currentUser = try await fetchCurrentUser() else {
            print("No current user found")
            return []
        }
        
        guard let friends = currentUser.friends, !friends.isEmpty else {
            print("No friends found")
            return []
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        var allDreams: [DreamCloud] = []
        
        for friendID in friends {
            let dreamsCollection = db.collection("UserDreams")
                .document(friendID)
                .collection("dreams")
            
            do {
                let snapshot = try await dreamsCollection
                    .whereField("deleted", isEqualTo: false)
                    .whereField("isPublic", isEqualTo: true)
                    .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                    .whereField("date", isLessThan: Timestamp(date: endOfDay))
                    .order(by: "date", descending: true)
                    .getDocuments()
                
                let friendDreams: [DreamCloud] = snapshot.documents.compactMap { document in
                    do {
                        return try document.data(as: DreamCloud.self)
                    } catch {
                        print("Failed to decode friend dream \(document.documentID): \(error)")
                        return nil
                    }
                }
                
                allDreams.append(contentsOf: friendDreams)
            } catch {
                print("Error fetching friend's dreams for \(friendID): \(error.localizedDescription)")
            }
        }
        
        return allDreams
    }
    
    /// Uploads a given DreamCloud to Firestore.
    private func uploadDreamToCloud(dreamCloud: DreamCloud, userID: String) {
        let dreamsCollection = db.collection("UserDreams")
            .document(userID)
            .collection("dreams")

        dreamsCollection.whereField("uuid", isEqualTo: dreamCloud.uuid).getDocuments { snapshot, error in
            if let error = error {
                print("Error checking for existing dream: \(error.localizedDescription)")
                return
            }

            if let document = snapshot?.documents.first {
                // Update the existing document.
                let docRef = document.reference
                do {
                    let data = try Firestore.Encoder().encode(dreamCloud)
                    docRef.setData(data, merge: true) { error in
                        if let error = error {
                            print("Error updating dream: \(error.localizedDescription)")
                        } else {
                            print("Dream updated successfully!")
                        }
                    }
                } catch {
                    print("Error encoding DreamCloud: \(error)")
                }
            } else {
                // Create a new document.
                let newDocRef = dreamsCollection.document()
                do {
                    var data = try Firestore.Encoder().encode(dreamCloud)
                    data["id"] = newDocRef.documentID
                    newDocRef.setData(data) { error in
                        if let error = error {
                            print("Error creating new dream: \(error.localizedDescription)")
                        } else {
                            print("New dream created successfully!")
                        }
                    }
                } catch {
                    print("Error encoding DreamCloud: \(error)")
                }
            }
        }
    }
}
