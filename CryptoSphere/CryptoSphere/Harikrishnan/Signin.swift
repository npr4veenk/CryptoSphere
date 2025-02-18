import SwiftUI
import GoogleSignIn
//import GoogleSignInSwift
import SwiftData



struct ContentView: View {
    @Query private var sessions: [UserSession]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.globalViewModel) private var globalViewModel
    @State var currentSession: UserSession = UserSession()
    
    @Namespace var profileAnimation
    
    var body: some View {
        VStack {
            if currentSession.isSignedIn {
                VStack{
                    Text("Hello")
                    AllUsersListView(profileAnimation: profileAnimation, onSelectUser: { user, _ in
                        withAnimation{
                            AnyView(ChatView(toUser: user, profileAnimation: profileAnimation))
                        }
                    })
                    
                    // WalletView()
                }
                .onAppear {
                    Task{
                        await ServerResponce.shared.addUser(user: globalViewModel.session)
                    }
                }
            } else {
                signInButton()
            }
        }
    }
    
    
    @ViewBuilder private func signInButton() -> some View {
        Text("hello")

        .frame(width: 200, height: 50)
    }
    

    

}

#Preview {
    ContentView()
        .modelContainer(for: UserSession.self, inMemory: true)
}
