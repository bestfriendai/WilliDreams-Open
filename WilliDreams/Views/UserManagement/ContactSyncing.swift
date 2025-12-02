//
//  ContactSyncing.swift
//  WilliDreams
//
//  Created by William Gallegos on 3/18/25.
//

@preconcurrency import Contacts
import Firebase

struct ContactSyncing {
    func isGranted() async -> Bool {
        let store = CNContactStore()
        return await withCheckedContinuation { continuation in
            let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            continuation.resume(returning: authorizationStatus == .authorized)
        }
    }

    func requestContactsPermission() async -> Bool {
        let store = CNContactStore()
        return await withCheckedContinuation { continuation in
            store.requestAccess(for: .contacts) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func fetchContacts() async -> [(phoneNumber: String, countryCode: String)] {
        let store = CNContactStore()
        let keysToFetch: [CNKeyDescriptor] = [CNContactPhoneNumbersKey as CNKeyDescriptor]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                var contacts: [(phoneNumber: String, countryCode: String)] = []
                do {
                    try store.enumerateContacts(with: fetchRequest) { contact, _ in
                        contact.phoneNumbers.forEach { phone in
                            let phoneNumber = phone.value.stringValue.filter { $0.isNumber }
                            let countryCode = "" // You can retrieve the country code if needed, or leave it empty
                            contacts.append((phoneNumber, countryCode))
                        }
                    }
                    DispatchQueue.main.async {
                        continuation.resume(returning: contacts)
                    }
                } catch {
                    print("Error fetching contacts: \(error)")
                    DispatchQueue.main.async {
                        continuation.resume(returning: [])
                    }
                }
            }
        }
    }

    func checkIfContactsUseApp(_ contacts: [(phoneNumber: String, countryCode: String)]) async -> [User] {
        guard !contacts.isEmpty else { return [] }

        let db = Firestore.firestore()
        let usersRef = db.collection("Users")
        var users: [User] = []
        let batchSize = 30

        do {
            for i in stride(from: 0, to: contacts.count, by: batchSize) {
                let batch = contacts[i..<min(i + batchSize, contacts.count)]

                let querySnapshot = try await usersRef
                    .whereField("phoneNumber", in: batch.map { $0.phoneNumber })
                    .whereField("countryCode", in: batch.map { $0.countryCode })
                    .getDocuments()

                for document in querySnapshot.documents {
                    if let user = try? document.data(as: User.self) {
                        users.append(user)
                    }
                }
            }
        } catch {
            print("Error fetching users: \(error)")
        }
        return users
    }

    func syncContacts() async {
        guard await requestContactsPermission() else {
            print("Permission to access contacts was denied.")
            return
        }

        let contacts = await fetchContacts()
        let users = await checkIfContactsUseApp(contacts) // Now passing the correct type
        await updateUserWithPhoneNumber(users)
        print("Friends using the app: \(users)")
    }

    func updateUserWithPhoneNumber(_ users: [User]) async {
        do {
            guard var currentUser = try await fetchCurrentUser() else { return }
            
            if let firstUser = users.first {
                currentUser.phoneNumber = firstUser.phoneNumber
            }
            
            currentUser.friends = users.map { $0.userUID }
            saveUpdatedUser(currentUser)
        } catch {
            print("Error updating user: \(error)")
        }
    }

    func saveUpdatedUser(_ user: User) {
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(user.userUID)

        userRef.setData([
            "phoneNumber": user.phoneNumber ?? "",
            "friends": user.friends ?? []
        ], merge: true) { error in
            if let error = error {
                print("Error updating user: \(error)")
            } else {
                print("User updated successfully!")
            }
        }
    }

    func getContactsAndCheckUsers() async -> [User] {
        guard await isGranted() else {
            print("Permission to access contacts is not granted.")
            return []
        }
        
        let contacts = await fetchContacts()
        return await checkIfContactsUseApp(contacts) // HERE
    }
}

extension ContactSyncing {
    // Append the user's phone number and country code to Firebase
    func appendPhoneNumberToFirebase(userUID: String, phoneNumber: String, countryCode: String) async {
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(userUID)
        
        do {
            try await userRef.setData([
                "phoneNumber": phoneNumber,
                "countryCode": countryCode
            ], merge: true)
            print("Phone number and country code updated successfully.")
        } catch {
            print("Error updating phone number and country code: \(error)")
        }
    }
    
    // Get the user's phone number and country code from Firebase
    func getPhoneNumberFromFirebase(userUID: String) async -> (phoneNumber: String?, countryCode: String?) {
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(userUID)
        
        do {
            let document = try await userRef.getDocument()
            if let data = document.data() {
                let phoneNumber = data["phoneNumber"] as? String
                let countryCode = data["countryCode"] as? String
                return (phoneNumber, countryCode)
            }
        } catch {
            print("Error fetching phone number and country code: \(error)")
        }
        return (nil, nil)
    }

    // Get users with specific phone numbers
    func getUserWithPhoneNumbers(phoneNumbers: [String]) async -> [User] {
        let db = Firestore.firestore()
        let usersRef = db.collection("Users")
        var users: [User] = []

        guard !phoneNumbers.isEmpty else { return [] }
        let batchSize = 30

        do {
            for i in stride(from: 0, to: phoneNumbers.count, by: batchSize) {
                let batch = Array(phoneNumbers[i..<min(i + batchSize, phoneNumbers.count)])
                let querySnapshot = try await usersRef.whereField("phoneNumber", in: batch).getDocuments()
                
                for document in querySnapshot.documents {
                    if let user = try? document.data(as: User.self) {
                        users.append(user)
                    }
                }
            }
        } catch {
            print("Error fetching users by phone number: \(error)")
        }

        return users
    }
}
