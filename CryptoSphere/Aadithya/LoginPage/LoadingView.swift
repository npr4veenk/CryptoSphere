import SwiftUI
import SDWebImageSwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0)
                .ignoresSafeArea()

            WebImage(url: URL(string: "https://raw.githubusercontent.com/Aadithya-Git/Demo/main/loadingAnimation-unscreen.gif"))
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .background(.clear)
                .scaleEffect(1.3)
        }
    }
}

#Preview {
    LoadingView()
}
