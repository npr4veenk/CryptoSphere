//
//  WebSocketManager.swift
//  CryptoSphere
//
//  Created by Harikrishnan V on 2025-02-12.
//


import Foundation
import Combine


class WebSocketManager: ObservableObject {
    @Published var messages: [Message] = []
    private var webSocketTask: URLSessionWebSocketTask?
    private let username: String
    private let urlSession: URLSession

    private(set) var isConnected: Bool = false
    

    init() {
        self.username = UserSession.shared?.userName ?? "Krishnan"
        let configuration = URLSessionConfiguration.default
        self.urlSession = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
//        Task { await connect() }
    }

    // Connect to WebSocket server
    func connect() async {
        await disconnect()
        guard let url = URL(string: "wss://cryptospyer.loca.lt/ws/\(username)") else {
            print("❌ Invalid WebSocket URL")
            return
        }
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        if webSocketTask?.state == .running {
            print("✅ WebSocket connection successful! \(url.absoluteString)")
            isConnected = true
            await receiveMessages()
        } else {
            print("❌ WebSocket connection failed! Retrying in 5 sec...")
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await connect()
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
                print("✅ Message sent successfully \(jsonString ?? "")")
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
                    print("📩 Received raw message: \(message)")
                    if let jsonData = message.data(using: .utf8) {
                        do {
                            let receivedMessage = try JSONDecoder().decode(Message.self, from: jsonData)
                            print("✅ Received Message: \(receivedMessage)")
                            
                            DispatchQueue.main.async {
                                self.messages.append(receivedMessage)
                            }
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
