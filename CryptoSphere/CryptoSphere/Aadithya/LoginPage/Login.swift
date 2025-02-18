//
//  Login.swift
//  CS_LoginPage
//
//  Created by Aadithya K S on 16/02/25.
//

import SwiftUI

// MARK: Assigned constants for screen size in Global Scope
let height = UIScreen.main.bounds.height
let width = UIScreen.main.bounds.width
var slideSheet = false

struct Login: View {
    
    @State private var currentOffset: CGFloat = 0
    @GestureState private var gestureOffset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    @State private var visibleCount = 0  // Tracks how many sentences are visible
    @State private var scale = 0.0
    @State private var secScale = 0.0
    @State private var slideInitial = 140.0
    @State private var infoPadding = 30.0
    
    let sentences = [
        "You're only a few steps away",
        "from CryptoSphere"
    ]
    
    var body: some View {
        ZStack {
            IntroPlayerWrapper()
                .ignoresSafeArea()
                .blur(radius: getBlurRadius())
            
            ZStack {
                Color(.grayButton)
                    .frame(width: width, height: height)
                    .clipShape(CustomCorner(corners: [.topLeft, .topRight], radius: 30))
                    .padding(.top, 100)
                
                VStack {
                    Capsule()
                        .fill(.primaryTheme)
                        .frame(width: 70, height: 12)
                        .padding(.top, 120)
                    
                    VStack(spacing: 10) {
                        ForEach(sentences.indices, id: \.self) { index in
                            Text(sentences[index])
                                .font(.custom("Rockwell", size: 25))
                                .foregroundStyle(.white)
                                .opacity(visibleCount > index ? 1 : 0)
                        }
                    }
                    .padding(.top, 40)
                    
                    Button(action: {
                        slideSheet = true
                        showSheet()
                    }) {
                        Text("Get Started")
                            .font(.custom("ZohoPuvi-Bold", size: 24))               .foregroundColor(.white)
                            .frame(width: 280, height: 60)
                    }
                    .background(.primaryTheme)
                    .clipShape(RoundedRectangle(cornerRadius: 65))
                    .padding(.top, 40)
                    .scaleEffect(scale)
                    
                    VStack{
                        Page()
                            .padding(.top, infoPadding)
                        
                        Button(action: {}) {
                            HStack(spacing: 15){
                                Image("GoogleIcon")
                                    .resizable()
                                    .frame(width: 35, height: 35)
                                
                                Text("Sign in with Google")
                                    .font(.custom("Rockwell-Bold", size: 25))
                                    .foregroundColor(.grayButton)
                                    .padding(.top, 10)
                            }
                            .frame(width: 330, height: 60)
                        }
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.top, 30)
                        .scaleEffect(secScale)
                    }
                    
                    Button(action: {}) {
                        HStack(spacing: 20){
                            Image(systemName: "apple.logo")
                                .resizable()
                                .frame(width: 35, height: 40)
                                .foregroundStyle(.black)
                            
                            Text("Sign in with Apple")
                                .font(.custom("Rockwell-Bold", size: 25))
                                .foregroundColor(.grayButton)
                                .padding(.top, 10)
                        }
                        .frame(width: 330, height: 60)

                    }
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 30)
                    .scaleEffect(secScale)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .offset(y: height - slideInitial)
            .offset(y: -currentOffset > height - 380 ? -(height - 380) : currentOffset)
            .gesture(
                DragGesture()
                    .updating($gestureOffset) { value, out, _ in
                        out = value.translation.height
                        onChange()
                    }
                    .onEnded { _ in
                        showSheet()
                    }
            )
        }
        .onAppear {
        
            DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
                withAnimation(.easeOut(duration: 0.5)){
                    slideInitial = 380
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                for i in 0..<sentences.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i) * 0.8)) {
                        withAnimation(.easeOut(duration: 1.2)) {
                            visibleCount += 1
                        }
                    }
            }
            
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        scale = 1
                    }
                }
            }
        }
    }
    
    func onChange() {
        DispatchQueue.main.async {
            self.currentOffset = gestureOffset + lastOffset
        }
    }
    
    func showSheet() {
        withAnimation {
            let maxDrag = height - 380
            if (-currentOffset > maxDrag / 4 || slideSheet == true) {
                currentOffset = -maxDrag
                scale = 0
                infoPadding = -100
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation{
                        secScale = 1
                    }
                }
            } else {
                currentOffset = 0
                infoPadding = 20
                scale = 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation{
                        secScale = 0
                    }
                }
            }
            
            lastOffset = currentOffset
            slideSheet = false
        }
    }

    
    func getBlurRadius() -> CGFloat {
        let progress = -currentOffset / (height - 380)
        return progress * 10
    }
}

struct Page: View {
    @State private var selectedTab = 0
    private let tabCount = 3 // Number of tabs

    var body: some View {
        TabView(selection: $selectedTab) {
            OnboardView(imageName: "chart.bar.fill", title: "Charts", description: "Visualize real-time and historical crypto price trends with interactive charts.")
                .tag(0)
            
            OnboardView(imageName: "qrcode.viewfinder", title: "Scan QR", description: "Instantly scan QR codes to send or receive crypto payments, add wallet addresses.")
                .tag(1)
            
            OnboardView(imageName: "bubble.fill", title: "Chat", description: "Securely connect with your trade partner in real-time to discuss deals, negotiate prices.")
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .frame(width: width * 0.9, height: 400)
        .onAppear {
            startAutoScroll()
        }
    }

    private func startAutoScroll() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            withAnimation {
                selectedTab = (selectedTab + 1) % tabCount
            }
        }
    }
}

struct OnboardView: View{
    
    let imageName : String
    let title : String
    let description : String
    
    var body : some View{
        VStack(spacing: 20){
            Image(systemName: imageName)
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.primaryTheme)
            
            Text(title)
                .font(.custom("Verdana-Bold", size: 30))
                .tracking(2)
            
            Text(description)
                .font(.custom("Rockwell", size: 20))
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 40)
    }
}


#Preview {
    Login()
}
