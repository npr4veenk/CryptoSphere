//
//  Session.swift
//  Real app
//
//  Created by Harikrishnan V on 2025-01-31.
//

import Foundation
import SwiftData

@Model
class UserSession {
    static var shared: UserSession? = UserSession(isSignedIn: true, userName: preview, emailAddress: "demo@gmail.com", profileImageURL: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTZ0FpBg5Myb9CQ-bQpFou9BY9JXoRG6208_Q&s")
    
    var isSignedIn: Bool
    var userName: String?
    var emailAddress: String?
    var profileImageURL: String?
    
    init(isSignedIn: Bool = false, userName: String? = nil, emailAddress: String? = nil, profileImageURL: String? = nil) {
        self.isSignedIn = isSignedIn
        self.userName = userName
        self.emailAddress = emailAddress
        self.profileImageURL = profileImageURL
    }
}
