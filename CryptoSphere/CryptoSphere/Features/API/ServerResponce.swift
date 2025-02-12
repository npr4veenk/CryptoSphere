//
//  ServerResponce.swift
//  CryptoSphere
//
//  Created by Harikrishnan V on 2025-02-12.
//

import Foundation


class ServerResponce {
    
    static let shared = ServerResponce()
    
    var baseURL = "https://snake-loving-bear.ngrok-free.app"
    
    func getUsers() async throws -> [User] {
        guard let url = URL(string: "\(baseURL)/get_users") else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let users = try JSONDecoder().decode([User].self, from: data)
        return users
    }
    
    func getChatHistory(to: String) async throws -> [Message]{
        guard let url = URL(string: "\(baseURL)/get_chat_history/\(UserSession.shared?.userName ?? "john")/\(to)") else { return []}
        let (data, _) = try await URLSession.shared.data(from: url)
        let msgs = try JSONDecoder().decode([Message].self, from: data)
        return msgs
    }
    
    func fetchuserholdings(userName: String) async throws -> [UserHolding] {
        guard let url = URL(string: "\(baseURL)/userholdings/\(userName)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        do {
            return try JSONDecoder().decode([UserHolding].self, from: data)
        } catch {
            print("decode error")
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Failed to decode UserHoldings"))
        }
    }
    
    func fetchCoinAddresses(userName: String, coinId: Int) async throws -> String {
        guard let url = URL(string: "\(baseURL)/get_user_coin_address/\(userName)/\(coinId)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let address = jsonResponse["address"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        return address
    }
    
    
}


struct UserHolding: Decodable, Hashable, Identifiable {
    let email: String
    let coin: CoinDetails
    let quantity: Double
    
    var id: UUID {
        UUID()
    }
}

