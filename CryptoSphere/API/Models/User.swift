//
//  User.swift
//  CryptoSphere
//
//  Created by Harikrishnan V on 2025-03-17.
//


import Foundation

struct User: Decodable, Hashable, Encodable {
    let email: String
    let username: String
    let password: String
    let profilePicture: String
    
}

