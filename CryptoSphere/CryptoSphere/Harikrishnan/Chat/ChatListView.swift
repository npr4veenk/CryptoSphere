import SwiftUI
import Combine
import Kingfisher

let preview = "Krishnan"

struct ChatListView: View {
    @State private var users: [User] = []
    @Namespace private var profileAnimation
    @State private var showNotification = false
    
    var body: some View {
        ZStack{
            VStack{
                Text("\(preview)")
                    .font(.custom("ZohoPuvi-Bold", size: 25))
                UsersListView(profileAnimation: profileAnimation, onSelectUser: { user, _ in
                    withAnimation{
                        AnyView(ChatView(toUser: user, profileAnimation: profileAnimation).modelContainer(for: MessageModel.self))
                    }
                })
            }
            
            VStack {
                Spacer()
                if let lastMessage = WebSocketManager.shared.messages.last, showNotification {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(lastMessage.from)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))

                        Text(lastMessage.message)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(12)
                    .shadow(radius: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showNotification)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showNotification = false
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 50)
        }
        .onChange(of: WebSocketManager.shared.messages) {
            withAnimation {
                showNotification = true
            }
        }
    }

}


#Preview {
    ChatListView()
}

