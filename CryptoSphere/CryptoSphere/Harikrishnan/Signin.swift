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
        .onAppear { restoreSession() }
    }
    
    
    @ViewBuilder private func signInButton() -> some View {
        Text("hello")
            .onTapGesture {
                let targetSession = UserSession(isSignedIn: false)
                modelContext.insert(targetSession)
                
                GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { result, error in
                    guard let user = result?.user, error == nil else {
                        print("Sign in error: \(String(describing: error))")
                        return
                    }
                    
                    targetSession.isSignedIn = true
                    targetSession.userName = user.profile?.name
                    targetSession.emailAddress = user.profile?.email
                    targetSession.profileImageURL = user.profile?.imageURL(withDimension: 100)?.absoluteString
                    UserSession.shared = targetSession
                    currentSession = targetSession
                    
                    globalViewModel.session = User(email: targetSession.emailAddress ?? "", username: targetSession.userName ?? "", password: "Google Sign In", profilePicture: targetSession.profileImageURL ?? "")
                }
            }
        .frame(width: 200, height: 50)
    }
    
    private func restoreSession() {
        if sessions.isEmpty {
            return
        }
        
        let session = UserSession()
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            session.isSignedIn = user != nil && error == nil
            session.userName = user?.profile?.name
            session.emailAddress = user?.profile?.email
            session.profileImageURL = user?.profile?.imageURL(withDimension: 100)?.absoluteString
            currentSession = session
            UserSession.shared = session
            
            globalViewModel.session = User(email: session.emailAddress ?? "", username: session.userName ?? "", password: "Google Sign In", profilePicture: session.profileImageURL ?? "")
        }
    }
    
    private func getRootViewController() -> UIViewController {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            return UIViewController()
        }
        return rootViewController
    }
}

#Preview {
    ContentView()
        .modelContainer(for: UserSession.self, inMemory: true)
}
