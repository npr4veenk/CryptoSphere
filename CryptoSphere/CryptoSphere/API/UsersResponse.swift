import Foundation

struct User: Decodable, Hashable, Encodable {
    let email: String
    let username: String
    let password: String
    let profilePicture: String
    
}

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

class UsersResponse {
    var baseURL = "https://snake-loving-bear.ngrok-free.app"
    
    static let userResponse = UsersResponse()
    
    private init(baseURL: String = "https://61a8-182-74-243-51.ngrok-free.app") {
        self.baseURL = baseURL
    }
    
    func getAllUsers() async throws -> [User] {
        guard let url = URL(string: "\(baseURL)/get_users") else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let users = try JSONDecoder().decode([User].self, from: data)
        return users
    }
    
    func addUser(email: String, username: String, profilePicture: String) async throws {
        guard let url = URL(string: "\(baseURL)/add_user") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["email": email, "username": username, "profile_picture": profilePicture]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        _ = try await URLSession.shared.data(for: request)
    }
    
    func getChatHistory(from: String, to: String) async throws -> [Message]{
        guard let url = URL(string: "\(baseURL)/get_chat_history/\(from)/\(to)") else { return []}
        let (data, _) = try await URLSession.shared.data(from: url)
        let msgs = try JSONDecoder().decode([Message].self, from: data)
        return msgs
    }
}
