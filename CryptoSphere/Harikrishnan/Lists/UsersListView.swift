import SwiftUI
import AudioToolbox
import Kingfisher

struct UsersListView: View {
    
    @State private var searchText: String = ""
    @State private var users: [User] = []
    @State private var isLoading: Bool = true
    
    var profileAnimation: Namespace.ID
    @State private var isNavigating: User? = nil
    
    var onSelectUser: (Binding<User?>, Namespace.ID) -> AnyView
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            // Extract unique users from both `from` and `to`, maintaining order
            var seen = Set<String>()
            let orderedUsers = WebSocketManager.shared.messages.reversed()
                .compactMap { message -> [String]? in
                    return [message.from, message.to].filter { seen.insert($0).inserted }
                }
                .flatMap { $0 } // Flatten the array of arrays

            return users
                .filter { orderedUsers.contains($0.username) && $0.username != UserSession.shared?.userName}
                .sorted { (user1, user2) in
                    guard let index1 = orderedUsers.firstIndex(of: user1.username),
                          let index2 = orderedUsers.firstIndex(of: user2.username) else {
                        return false
                    }
                    return index1 < index2
                }
        } else {
            return users.filter { $0.username.localizedCaseInsensitiveContains(searchText) && $0.username != UserSession.shared?.userName }
        }
    }
    
    @Environment(\.globalViewModel) var globalViewModel
    
    var body: some View {
        if isLoading {
            Spacer()
            ProgressView("Loading users...")
                .onAppear { fetchUsers() }
            Spacer()
        } else if isNavigating != nil {
            onSelectUser($isNavigating, profileAnimation)
        } else {
            NavigationStack{
                ScrollView{
                    LazyVStack(alignment: .leading, spacing: 16){
                        ForEach(filteredUsers, id: \.self) { user in
                            Button {
                                withAnimation(.easeIn(duration: 0.2)) {
                                    isNavigating = user
                                }
                                globalViewModel.selectedUser = user
                            } label: {
                                VStack (alignment: .leading){
                                    HStack(spacing: 16) {
                                        KFImage(URL(string: user.profilePicture))
                                            .resizable()
                                            .matchedGeometryEffect(id: "profile_\(user.profilePicture)", in: profileAnimation)
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            highlightedUsername(user.username)
                                                .font(.headline)
                                                .foregroundStyle(Color.primary)
                                                .matchedGeometryEffect(id: "username_\(user.username)", in: profileAnimation)
                                            Text(user.email)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    
                                    Divider()
                                }
                            }
                        }
                        .searchable(text: $searchText, prompt: "Search users")
                        .animation(.easeOut(duration: 0.3), value: filteredUsers)
                    }
                }
                .padding(.horizontal)
            }
        }
        
    }
    
    
    private func fetchUsers() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                users = try await ServerResponce.shared.getUsers()
            } catch {
                print("Failed to fetch users: \(error.localizedDescription)")
            }
        }
    }
    
    private func highlightedUsername(_ username: String) -> Text {
        guard let range = username.lowercased().range(of: searchText.lowercased()) else {
            return Text(username)
        }
        
        let before = Text(String(username[..<range.lowerBound]))
        let highlighted = Text(String(username[range])).foregroundColor(.orange)
        let after = Text(String(username[range.upperBound...]))
        
        return before + highlighted + after
    }
}

// MARK: -

struct ChatView: View {
    @Binding var toUser: User?
    @State private var webSocketManager =  WebSocketManager.shared
    
    var filteredMessages: [Message] {
        webSocketManager.messages.filter { msg in
            msg.from == toUser?.username || msg.to == toUser?.username
        }
    }
    
    @State private var messageText = ""
    @Environment(\.globalViewModel) var globalViewModel
    
    var profileAnimation: Namespace.ID
    
    var body: some View {
        VStack {
            ChatNavBar
                .onAppear {
                    globalViewModel.selectedUser = toUser!
                }
                .onDisappear {
                    globalViewModel.selectedCoin = UserHolding(email: "", coin: CoinDetails(id: 0, coinName: "", coinSymbol: "", imageUrl: ""), quantity: 2)
                    
                    globalViewModel.selectedUser = User(email: "", username: "", password: "", profilePicture: "")
                }
            
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredMessages) { msg in
                            ChatBubbleView(message: msg, isCurrentUser: msg.from == globalViewModel.session.username)
                                .id(msg.id)
                        }
                    }
                    .onChange(of: filteredMessages) {
                        withAnimation {
                            scrollView.scrollTo(webSocketManager.messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onAppear {
                        withAnimation {
                            scrollView.scrollTo(filteredMessages.last?.id, anchor: .bottom)
                        }
                    }
                }
                .padding(.top, 8)
            }
            
            ChatInputView(messageText: $messageText, onSend: sendMessage)
                .padding()
        }
        .navigationBarHidden(true)
    }
    
    var ChatNavBar: some View {
        HStack (alignment: .top){
            
            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    toUser = nil
                }
            }) {
                Image(systemName: "chevron.backward")
                    .foregroundColor(.blue)
                    .padding(10)
            }
            
            KFImage(URL(string: toUser?.profilePicture ?? " "))
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .matchedGeometryEffect(id: "profile_\(toUser?.profilePicture ?? " ")", in: profileAnimation)
                .padding(.horizontal, 10)
            
            VStack(alignment: .leading, spacing: 2){
                Text(toUser?.username ?? " ")
                    .font(.custom("ZohoPuvi-Semibold", size: 20))                    .foregroundColor(.primary)
                    .matchedGeometryEffect(id: "username_\(toUser?.username ?? " ")", in: profileAnimation)
                
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Online")
                        .font(.custom("ZohoPuvi-Bold", size: 16))
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let newMessage = Message(from: globalViewModel.session.username, to: toUser?.username ?? " ", message: messageText, timestamp: Int(Date().timeIntervalSince1970))
        messageText = ""
        Task {
            await WebSocketManager.shared.sendMessage(to: toUser?.username ?? " ", message: newMessage.message)
        }
    }
}

struct ChatInputView: View {
    @Binding var messageText: String
    var onSend: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    @State private var isSheetPresented = false
    
    var body: some View {
        HStack {
            // Pay Button (Hides when TextField is focused)
            if !isTextFieldFocused {
                Button(action: {
                    isSheetPresented.toggle()
                }) {
                    Text("Pay")
                        .font(.custom("ZohoPuvi-Semibold", size: 20))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.primaryTheme, in: RoundedRectangle(cornerRadius: 8)) //
                        .foregroundColor(Color("FontColor"))
                        .shadow(color: .primaryTheme.opacity(0.1), radius: 4, x: 0, y: 2) // Adds a subtle
                }
                .transition(.move(edge: .leading))
                .sheet(isPresented: $isSheetPresented) { // Sheet content
                    CoinHoldingListView(hasNavigate: true)
                }
            }
            
            // Text Input Field (Expands when focused)
            TextField("Type a message...", text: $messageText)
                .padding(12)
                .font(.custom("ZohoPuvi-Semibold", size: 18))
                .background(Color("GrayButtonColor"), in: RoundedRectangle(cornerRadius: 12))
                .focused($isTextFieldFocused) // Track focus
                .frame(maxWidth: isTextFieldFocused ? .infinity : 250) // Expands when focused
                .onTapGesture {
                    isTextFieldFocused = true // Ensure focus is set when tapped
                }
            
            // Send Button
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(messageText.isEmpty ? .white : .primaryTheme)
                    .padding(12)
                    .background(messageText.isEmpty ? Color("GrayButtonColor") : .white, in: Circle())
            }
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .shadow(radius: 5)
        .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
    }
}


#Preview {
    @Previewable @Namespace var profileAnimation
    UsersListView(profileAnimation: profileAnimation, onSelectUser: { user, _ in
        AnyView(ChatView(toUser: user, profileAnimation: profileAnimation))
    })
}

