//
//  Message.swift
//  CryptoSphere
//
//  Created by Harikrishnan V on 2025-03-17.
//

import Foundation

struct Message: Decodable, Encodable, Identifiable, Equatable {
    var id = UUID()
    
    let from: String
    let to: String
    let message: String
    let timestamp: Int
    
    private enum CodingKeys: String, CodingKey {
        case from, to, message, timestamp
    }
}
