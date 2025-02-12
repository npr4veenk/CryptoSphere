import SwiftUI

struct ChatBubbleView: View {
    let message: Message
    let isCurrentUser: Bool
    private let maxBubbleWidth: CGFloat = UIScreen.main.bounds.width * 0.75
    @State private var isMessageVisible = false
    
    @State private var coinURL = ""
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if message.message.hasPrefix("{payment}") {
                    VStack {
                        Text(isCurrentUser ? "Payment Sent" : "Payment Received")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .frame(maxWidth: maxBubbleWidth, alignment: isCurrentUser ? .trailing : .leading)
                    .offset(x: isMessageVisible ? 0 : (isCurrentUser ? 200 : -200),
                            y: isMessageVisible ? 0 : (isCurrentUser ? 140 : -140))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .opacity(isMessageVisible ? 1 : 0)
                } else {
                    Text(message.message)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(isCurrentUser ? .primary : .white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(messageBackground)
                        .clipShape(RoundedCornerShape(radius: 18, corners: isCurrentUser ? [.topLeft, .bottomLeft, .bottomRight] : [.topRight, .bottomLeft, .bottomRight]))
                        .frame(maxWidth: maxBubbleWidth, alignment: isCurrentUser ? .trailing : .leading)
                        .offset(x: isMessageVisible ? 0 : (isCurrentUser ? 200 : -200),
                                y: isMessageVisible ? 0 : (isCurrentUser ? 140 : -140))
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                        .opacity(isMessageVisible ? 1 : 0)
                }
                
                timestampView
                    .offset(x: isMessageVisible ? 0 : (isCurrentUser ? 300 : -300))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            
            if !isCurrentUser { Spacer() }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4)) {
                isMessageVisible = true // Make the message visible after delay
            }
        }
    }
    
    @ViewBuilder
     private var messageBackground: some View {
         if isCurrentUser {
             Color(UIColor.systemGray5) // Light gray for other user
                 .cornerRadius(18)
                 .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
         } else {
             LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.45), Color.orange.opacity(0.65)]),
                 startPoint: .topLeading,
                 endPoint: .bottomTrailing
             )
             .cornerRadius(18)
         }
     }
    
    private var timestampView: some View {
        Text(formatTimestamp(message.timestamp))
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(.gray)
            .padding(.top, 2)
            .padding(.horizontal, 4)
    }
    
    private func formatTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct RoundedCornerShape: Shape {
    let radius: CGFloat
    let corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    VStack(spacing: 8) {
        ChatBubbleView(
            message: Message(
                from: "user1",
                to: "user2",
                message: "{payment}Hello! This is a sample message",
                timestamp: Int(Date().timeIntervalSince1970)
            ),
            isCurrentUser: false
        )
        
        ChatBubbleView(
            message: Message(
                from: "user2",
                to: "user1",
                message: "Hi! This is my reply",
                timestamp: Int(Date().timeIntervalSince1970)
            ),
            isCurrentUser: true
        )
    }
    .padding()
    .background(Color(.systemBackground))
}
