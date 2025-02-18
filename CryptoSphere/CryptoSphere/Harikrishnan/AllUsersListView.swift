import SwiftUI
import Kingfisher

struct AllUsersListView: View {
    
    @State private var searchText: String = ""
    @State private var users: [User] = []
    @State private var isLoading: Bool = false
    
    var profileAnimation: Namespace.ID
    @State private var isNavigating: User? = nil
    
    var onSelectUser: (Binding<User?>, Namespace.ID) -> AnyView
    
    var filteredUsers: [User] {
        searchText.isEmpty ? users : users.filter { $0.username.localizedCaseInsensitiveContains(searchText) }
    }
    
    @Environment(\.globalViewModel) var globalViewModel
    
    var body: some View {
        NavigationStack {
            if isLoading {
                Spacer()
                ProgressView("Loading users...")
                Spacer()
            } else if isNavigating != nil {
                onSelectUser($isNavigating, profileAnimation)
            } else {
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
                                        AsyncImage(url: URL(string: user.profilePicture)) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                            case .success(let image):
                                                image.resizable()
                                            case .failure:
                                                Image(systemName: "person.circle.fill")
                                                    .resizable()
                                                    .foregroundColor(.secondary)
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
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
                        .animation(.easeOut(duration: 0.3), value: filteredUsers)
                        .refreshable {
                            fetchUsers()
                        }
                    }
                }
                .padding(.horizontal)
                .navigationTitle("Users")
                .searchable(text: $searchText, prompt: "Search users")
            }
        }
        .onAppear { fetchUsers() }
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
    @State var from: String = ""
    @State private var messageHistory: [Message] = []
    @State private var messageText = ""
    @Environment(\.globalViewModel) var globalViewModel
    
    var profileAnimation: Namespace.ID
    
    var body: some View {
        VStack {
            ChatNavBar
            
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messageHistory) { msg in
                            ChatBubbleView(message: msg, isCurrentUser: msg.from == globalViewModel.session.username)
                                .id(msg.id)
                        }
                    }
                    .onChange(of: WebSocketManager.shared.messages) {
                        if let newMessage = WebSocketManager.shared.messages.last {
                            messageHistory.append(newMessage)
                        }
                    }
                    .onChange(of: messageHistory.count) {
                        withAnimation {
                            scrollView.scrollTo(messageHistory.last?.id, anchor: .bottom)
                        }
                    }
                }
                .padding(.top, 8)
                .listStyle(.plain)
            }
            
            ChatInputView(messageText: $messageText, onSend: sendMessage)
                .padding()
        }
        .onAppear {
            from = globalViewModel.session.username
            Task {
                do {
                    messageHistory = try await ServerResponce.shared.getChatHistory(to: toUser?.username ?? " ")
                } catch {
                    print("Failed to load messages: \(error.localizedDescription)")
                }
            }
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
                    .font(.headline)
                    .foregroundColor(.primary)
                    .matchedGeometryEffect(id: "username_\(toUser?.username ?? " ")", in: profileAnimation)
                
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Online")
                        .font(.caption)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let newMessage = Message(from: from, to: toUser?.username ?? " ", message: messageText, timestamp: Int(Date().timeIntervalSince1970))
        
        messageHistory.append(newMessage)
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
                        .font(.system(size: 16, weight: .semibold)) // Slightly larger & bolder text
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color("primaryTheme").opacity(0.2), in: RoundedRectangle(cornerRadius: 8)) //
                        .foregroundColor(Color("FontColor"))
                        .shadow(color: Color("primaryTheme").opacity(0.1), radius: 4, x: 0, y: 2) // Adds a subtle
                }
                .transition(.move(edge: .leading))
                .sheet(isPresented: $isSheetPresented) { // Sheet content
                    AllCoinsListView(isUserHoldingCoins: true, onSelectCoin: { userCoin in
                        AnyView(SendView(userHolding: userCoin as! UserHolding))
                    })
                }
            }
            
            // Text Input Field (Expands when focused)
            TextField("Type a message...", text: $messageText)
                .padding(12)
                .background(Color(UIColor.systemGray6), in: RoundedRectangle(cornerRadius: 20))
                .focused($isTextFieldFocused) // Track focus
                .frame(maxWidth: isTextFieldFocused ? .infinity : 250) // Expands when focused
                .onTapGesture {
                    isTextFieldFocused = true // Ensure focus is set when tapped
                }
            
            // Send Button
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(messageText.isEmpty ? .gray : Color("primaryTheme"))
                    .padding(12)
                    .background(messageText.isEmpty ? Color.gray.opacity(0.1) : Color.orange.opacity(0.1), in: Circle())
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
    AllUsersListView(profileAnimation: profileAnimation, onSelectUser: { user, _ in
        AnyView(ChatView(toUser: user, profileAnimation: profileAnimation))
    })
}

