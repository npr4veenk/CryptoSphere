import SwiftUI
import Combine

struct ChatListView: View {
    @State private var users: [User] = []
    @Namespace private var profileAnimation
    
    var body: some View {
        AllUsersListView(profileAnimation: profileAnimation, onSelectUser: { user, _ in
            withAnimation{
                AnyView(ChatView(toUser: user, profileAnimation: profileAnimation))
            }
        })
        .navigationTitle("Chats")
    }

}

#Preview {
    ChatListView()
}
