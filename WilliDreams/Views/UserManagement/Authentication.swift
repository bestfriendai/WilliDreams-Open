//
//  Authentication.swift
//  WilliStudy
//
//  Created by William Gallegos on 1/3/25.
//

import AuthenticationServices

class AuthorizationControllerDelegateHandler: NSObject, ASAuthorizationControllerDelegate {
    var onCredentialRetrieved: ((String, String) -> Void)?
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let passwordCredential = authorization.credential as? ASPasswordCredential {
            onCredentialRetrieved?(passwordCredential.user, passwordCredential.password)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Authorization failed or canceled: \(error.localizedDescription)")
    }
    
    func checkForSavedPassword() {
        let passwordProvider = ASAuthorizationPasswordProvider()
        let request = passwordProvider.createRequest()
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
}
