import SwiftUI
import Combine
import Kingfisher

let preview = "Krishnan"

struct ChatListView: View {
    @State private var users: [User] = []
    @Namespace private var profileAnimation
    
    var body: some View {
        UsersListView(profileAnimation: profileAnimation, onSelectUser: { user, _ in
            withAnimation{
                AnyView(ChatView(toUser: user, profileAnimation: profileAnimation).modelContainer(for: MessageModel.self))
            }
        })
    }
}


#Preview {
    ChatListView()
}

