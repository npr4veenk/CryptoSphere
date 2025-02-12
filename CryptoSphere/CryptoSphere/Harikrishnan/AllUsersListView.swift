import SwiftUI

struct AllUsersListView: View {
    
    @State private var searchText: String = ""
    @State private var users: [User] = []
    @State private var isLoading: Bool = false
    
    @Namespace private var animation
    
    var onSelectUser: (Any) -> AnyView
    
    var filteredUsers: [User] {
        searchText.isEmpty ? users : users.filter { $0.username.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            if isLoading {
                Spacer()
                ProgressView("Loading users...")
                Spacer()
            } else if users.isEmpty {
                ContentUnavailableView("No Users Found", systemImage: "person.2.slash")
            } else {
                List(filteredUsers, id: \.self) { user in
                    NavigationLink {
                        onSelectUser(user)
                    } label: {
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
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                highlightedUsername(user.username)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        .transition(.slide)
                    }
                }
                .listStyle(.plain)
                .animation(.easeInOut(duration: 0.3), value: filteredUsers)
                .refreshable {
                    fetchUsers()
                }
            }
        }
        .navigationTitle("Users")
        .searchable(text: $searchText, prompt: "Search users")
        .onAppear { fetchUsers() }
    }
    
    private func fetchUsers() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                users = try await NetworkManager.shared.getUsers()
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
        let highlighted = Text(String(username[range])).foregroundColor(.blue)
        let after = Text(String(username[range.upperBound...]))
        
        return before + highlighted + after
    }
}
#Preview {
    AllUsersListView(onSelectUser: { user in
        AnyView(Text(""))
    })
}
