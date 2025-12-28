import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CryptoKit
import AuthenticationServices

class AuthManager: ObservableObject, @unchecked Sendable {
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isSignInWithAppleUsernamePromptEnabled = false
    
    @AppStorage("loginStatus") private var isLoggedIn = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("userUID") private var userID = ""
    
    var nonce: String?
    
    func loginUser(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
        }
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            try await fetchUser()
        } catch {
            await showError(message: "Incorrect email or password.")
        }
        await MainActor.run {
            isLoading = false
        }
    }
    
    func signUp(email: String, password: String, username: String) async {
        await MainActor.run {
            isLoading = true
        }
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
            let isAvailable = await checkUsernameAvailability(username: username.lowercased())
            guard isAvailable else {
                await showError(message: "Username is already in use. Please choose another one.")
                return
            }
            guard let currentUser = Auth.auth().currentUser else {
                await showError(message: "Failed to create user. Please try again.")
                return
            }
            let user = User(username: username.lowercased(), userEmail: email, userUID: currentUser.uid)
            try await saveUserToFirestore(user: user)
            await updateUserState(user: user)
        } catch {
            await showError(message: error.localizedDescription)
        }
        await MainActor.run {
            isLoading = false
        }
    }
    
    func signInWithApple(authorization: ASAuthorization) async {
        await MainActor.run {
            isLoading = true
        }
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            await showError(message: "Invalid Apple credential.")
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        guard let nonce = self.nonce else {
            await showError(message: "Nonce is missing or invalid.")
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            await showError(message: "Failed to retrieve identity token.")
            await MainActor.run { isLoading = false }
            return
        }
        
        let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName)
        
        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            let user = authResult.user
            self.userID = user.uid
            
            if let username = try? await fetchUsernameFromFirestore(userID: user.uid) {
                await updateUserState(username: username, userID: user.uid)
            } else {
                print("Username not found, prompting user to set a username.")
                await MainActor.run { self.isSignInWithAppleUsernamePromptEnabled = true }
            }
        } catch {
            let errorMessage = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
            print("Sign-in error: \(error)")
            await showError(message: errorMessage)
        }
        await MainActor.run {
            isLoading = false
        }
    }
    
    func resetPassword(email: String) async {
        // FIX: Wrap @Published property updates in MainActor.run
        await MainActor.run { isLoading = true }
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            await showError(message: "Failed to send password reset. Try again.")
        }
        await MainActor.run { isLoading = false }
    }
    
    private func fetchUser() async throws {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let userDocument = Firestore.firestore().collection("Users").document(userID)
        let user = try await userDocument.getDocument(as: User.self)
        await updateUserState(user: user)
    }
    
    private func checkUsernameAvailability(username: String) async -> Bool {
        do {
            let querySnapshot = try await Firestore.firestore()
                .collection("Users")
                .whereField("username", isEqualTo: username)
                .getDocuments()
            return querySnapshot.isEmpty
        } catch {
            return false
        }
    }
    
    private func saveUserToFirestore(user: User) async throws {
        try Firestore.firestore().collection("Users").document(user.userUID).setData(from: user)
    }
    
    private func fetchUsernameFromFirestore(userID: String) async throws -> String? {
        let document = try await Firestore.firestore().collection("Users").document(userID).getDocument()
        return document.get("username") as? String
    }
    
    private func updateUserState(user: User) async {
        await MainActor.run {
            self.userName = user.username
            self.userID = user.userUID
            self.isLoggedIn = true
        }
    }
    
    private func updateUserState(username: String, userID: String) async {
        await MainActor.run {
            self.userName = username
            self.userID = userID
            self.isLoggedIn = true
        }
    }
    
    func saveUsername(username: String) async {
        guard let userUID = Auth.auth().currentUser?.uid else {
            await showError(message: "User not authenticated.")
            return
        }
        
        let user = User(username: username.lowercased(),
                        userEmail: Auth.auth().currentUser?.email ?? "",
                        userUID: userUID)
        
        do {
            try Firestore.firestore().collection("Users").document(userUID).setData(from: user)
            await MainActor.run {
                self.userName = username.lowercased()
                self.userID = userUID
                self.isLoggedIn = true
            }
        } catch {
            await showError(message: "Failed to save username. Try again.")
        }
    }
    
    // Updated method to handle username prompt
    func handleUsernamePrompt(username: String) async {
        guard !username.isEmpty else {
            await showError(message: "Username cannot be empty.")
            return
        }
        
        let isAvailable = await checkUsernameAvailability(username: username.lowercased())
        if isAvailable {
            await saveUsername(username: username)
        } else {
            await showError(message: "Username is already taken. Please choose another.")
        }
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Generates a cryptographically secure random nonce string
    /// - Parameter length: The length of the nonce string (default 32)
    /// - Returns: A random nonce string, or nil if generation fails
    func randomNonceString(length: Int = 32) -> String? {
        guard length > 0 else { return nil }
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        // FIX: Return nil instead of crashing the app with fatalError
        guard errorCode == errSecSuccess else {
            print("WILLIDEBUG: Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            return nil
        }

        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }
    
    
    
    func showError(message: String) async {
        await MainActor.run {
            self.errorMessage = message
            self.showError = true
        }
    }
}
