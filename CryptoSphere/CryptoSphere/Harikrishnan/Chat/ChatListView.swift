import SwiftUI
import Combine

struct ChatListView: View {
    @State private var users: [User] = []
    
    var body: some View {
        VStack {
            UsersListView(onSelectUser: { user in
                AnyView(ChatView(toUser: (user as! User)))
            })
            Spacer()
        }
        .navigationTitle("Chats")
    }

}

struct ChatInputView: View {
    @Binding var messageText: String
    var onSend: () -> Void

    var body: some View {
        HStack {
            TextField("Type your message...", text: $messageText)
                .padding(12)
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.leading, 8)

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.title2)
                    .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(10)
            .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.2) : Color.blue.opacity(0.1))
            .clipShape(Circle())
        }
        .padding(.horizontal)
        .cornerRadius(30)
    }
}

#Preview {
    ChatListView()
        .environment(GlobalViewModel())
}
