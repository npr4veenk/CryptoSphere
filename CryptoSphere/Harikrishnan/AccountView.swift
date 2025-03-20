//
//  AccountView.swift
//  CryptoSphere
//
//  Created by Aadithya K S on 28/02/25.
//

import SwiftUI
import SwiftData

struct AccountView: View {
    @Environment(\.modelContext) var modelContext
    @Query var sessions: [UserSession]
    
    var body: some View {
        VStack(spacing: 30){
            
            ZStack{
                
                Color.primaryTheme
                    .clipShape(Circle())
                    .frame(width: 148, height: 148)
                
                if let imageUrl = UserSession.shared?.profileImageURL, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView() // Show a loading indicator
                        case .success(let image):
                            image.resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                        case .failure:
                            Image(systemName: "person.circle.fill") // Placeholder image on failure
                                .resizable()
                                .frame(width: 140, height: 140)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "person.circle.fill") // Default image if URL is nil
                        .resizable()
                        .frame(width: 140, height: 140)
                        .foregroundColor(.gray)
                }
                
            }
            
            VStack(spacing: 10){
                Text((UserSession.shared?.userName) ?? "")
                    .font(.custom("ZohoPuvi-Semibold", size: 26))
                
                Text(UserSession.shared?.emailAddress ?? "")
                    .font(.custom("ZohoPuvi-Semibold", size: 18))
            }
        }
        .padding(.top, 50)
        
        Spacer()

        Button(action: {
            if let session = sessions.first {
                modelContext.delete(session)  // Remove session from SwiftData
                try? modelContext.save()      // Save changes
            }
        }) {
            Text("Sign Out")
                .font(.custom("ZohoPuvi-Bold", size: 25))
                .foregroundColor(.white)
                .frame(width: 250, height: 50)
                .background(.primaryTheme)
                .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        
        Spacer()
        
    }
}

#Preview {
    AccountView()
}
