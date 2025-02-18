//
//  ServerResponce.swift
//  CryptoSphere
//
//  Created by Harikrishnan V on 2025-02-12.
//

import Foundation


class ServerResponce {
    
    static let shared = ServerResponce()
    
    var baseURL = "https://spyer.pagekite.me"
    
    func getUsers() async throws -> [User] {
        guard let url = URL(string: "\(baseURL)/get_users") else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let users = try JSONDecoder().decode([User].self, from: data)
        return users
    }
    
    func addUser(user: User) async {
        guard let url = URL(string: "\(baseURL)/add_user") else {
            return
        }
        print("Added")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(user)
            request.httpBody = jsonData
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let decodedResponse = try? JSONDecoder().decode([String: String].self, from: data) {
                print("Response: \(decodedResponse)")
            }
        } catch {
            print("Error: \(error)")
        }
        print(user.username)
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
    
    func fetchAllCoinDetails() async throws -> [CoinDetails] {
        guard let url = URL(string: "\(baseURL)/coins") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        do {
            return try JSONDecoder().decode([CoinDetails].self, from: data)
        } catch {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Failed to decode CoinDetails"))
        }
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

