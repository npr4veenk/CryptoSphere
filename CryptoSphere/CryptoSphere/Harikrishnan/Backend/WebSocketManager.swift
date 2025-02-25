//
//  WebSocketManager.swift
//  CryptoSphere
//
//  Created by Harikrishnan V on 2025-02-12.
//


import Foundation
import Combine

@Observable
class WebSocketManager {
    var messages: [Message] = [
//        Message(from: "Hari Krishnan", to: preview, message: "Hello, Bob!", timestamp: 1700000001),
//        Message(from: "bobmarley", to: preview, message: "Hey Alice, how are you?", timestamp: 1700000002),
//        Message(from: "charlieb", to: preview, message: "Hi Alice!", timestamp: 1700000003),
//        Message(from: "Praveen Kumar", to: preview, message: "Hey Eve, let's meet.", timestamp: 1700000004),
//        Message(from: "Eve", to: preview, message: "Sure, see you soon!", timestamp: 1700000005)
    ] {
        didSet {
            if let lastMessage = messages.last {
                print("\(lastMessage.from) -> \(lastMessage.to) = \(lastMessage.message)")
            }
        }
    }
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var username: String
    private let urlSession: URLSession

    private(set) var isConnected: Bool = false
    
    static let shared = WebSocketManager()
    
    init() {
        self.username = " "
        let configuration = URLSessionConfiguration.default
        self.urlSession = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }

    // Connect to WebSocket server
    func connect() async {
        self.username = UserSession.shared?.userName ?? preview
        await disconnect()
        guard let url = URL(string: "\(link)/ws/\(username)".replacingOccurrences(of: "http", with: "ws")) else {
            print("❌ Invalid WebSocket URL")
            return
        }

        try? await Task.sleep(for: .seconds(1))
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        try? await Task.sleep(for: .seconds(2))
        
        if webSocketTask?.state == .running {
            print("✅ WebSocket connection successful! \(url.absoluteString)")
            isConnected = true
            await getAllChatHistory()
            await receiveMessages()
        } else {
            print("❌ WebSocket connection failed! Retrying in 5 sec...")
            try? await Task.sleep(for: .seconds(5))
            await connect()
        }
    }
    
    private func getAllChatHistory() async {
        do {
            let history = try await ServerResponce.shared.getChatHistory(from: username)
            WebSocketManager.shared.messages.insert(contentsOf: history, at: 0)
        } catch {
            print("Failed to load messages: \(error.localizedDescription)")
        }
    }
    
    func sendMessage(to user: String, message: String) async {
        guard let webSocketTask else {
            print("❌ WebSocket is not connected")
            return
        }
        
        if webSocketTask.state != .running {
            print("❌ WebSocket is not active. Attempting to reconnect...")
            await connect()
            return
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        let messageObject = Message(from: username, to: user, message: message, timestamp: timestamp)
        do {
            let jsonData = try JSONEncoder().encode(messageObject)
            let jsonString = String(data: jsonData, encoding: .utf8)
            do {
                try await webSocketTask.send(.string(jsonString ?? ""))
            } catch {
                print("❌ Error sending message: \(error.localizedDescription)")
            }
        } catch {
            print("❌ Error encoding message: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func receiveMessages() async {
        guard let webSocketTask else {
            print("❌ No WebSocket task available. WebSocket not connected yet.")
            return
        }

        while isConnected {
            do {
                print("📡 Waiting for message...")
                let result = try await webSocketTask.receive()

                switch result {
                case .string(let message):
                    print(message)
                    if let jsonData = message.data(using: .utf8) {
                        do {
                            let receivedMessage = try JSONDecoder().decode(Message.self, from: jsonData)
                            WebSocketManager.shared.messages.append(receivedMessage)
                        } catch {
                            print("❌ Error decoding JSON: \(error.localizedDescription)")
                        }
                    }
                    
                case .data(let data):
                    print("✅ Received binary data: \(data)")

                @unknown default:
                    print("⚠️ Unknown WebSocket message type received.")
                }
            } catch {
                print("❌ Error receiving message: \(error.localizedDescription)")
                await connect()
                break
            }
        }
    }

    func disconnect() async {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        print("Disconnected from WebSocket server.")
        isConnected = false
    }
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

import SwiftData

@Model
class MessageModel {
    var from: String
    var to: String
    var message: String
    var timestamp: Int

    init(from: String, to: String, message: String, timestamp: Int) {
        self.from = from
        self.to = to
        self.message = message
        self.timestamp = timestamp
    }
}
