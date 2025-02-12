//
//  ChatView.swift
//  Real app
//
//  Created by Harikrishnan V on 2025-02-12.
//
import SwiftUI

struct ChatView: View {
    let toUser: User
    @State var from: String = ""
    @State private var messageHistory: [Message] = []
    @State private var messageText = ""
    @Environment(GlobalViewModel.self) var globalViewModel

    var body: some View {
        Text(from)
        
        HStack{
            
        }
        VStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack {
                        ForEach(messageHistory) { msg in
                            ChatBubbleView(message: msg, isCurrentUser: msg.from == from)
                                .id(msg.id)
                                .onAppear() {
                                    print(msg)
                                }
                        }
                    }
                    .onChange(of: globalViewModel.wsManager.messages.count) {
                        if let newMessage = globalViewModel.wsManager.messages.last {
                            messageHistory.append(newMessage)
                        }
                    }
                    .onChange(of: messageHistory.count) {
                        withAnimation {
                            scrollView.scrollTo(messageHistory.last?.id, anchor: .bottom)
                        }
                    }
                }
                .listStyle(.plain)

            }
            ChatInputView(messageText: $messageText, onSend: sendMessage)
        }
        .onAppear {
            from = globalViewModel.session.username
            Task{
                messageHistory = try await NetworkManager.shared.getChatHistory(to: toUser.username)
            }
        }
    }
    
    private func sendMessage() {
        messageHistory.append(Message(from: from ,to: toUser.username, message: messageText, timestamp: 20))
        Task {
            await globalViewModel.wsManager.sendMessage(to: toUser.username, message: messageText)
            messageText = ""
        }
    }
}

#Preview {
    ChatView(toUser: User(email: "", username: "Hari Krishnan", password: "", profilePicture: "https://randomuser.me/api/portraits/men/2.jpg"))
        .environment(GlobalViewModel())
}
