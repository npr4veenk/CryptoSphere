import SwiftUI
import CoreImage.CIFilterBuiltins
import Kingfisher

struct ReceiveView: View {
    let coin: CoinDetails
    @State var address: String?
    @Environment(\.globalViewModel) var globalViewModel
    var logoAnimation: Namespace.ID
    
    var body: some View {
        VStack(spacing: 16) {
            HStack{
                KFImage(URL(string: coin.imageUrl))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .shadow(radius: 4)
                    .matchedGeometryEffect(id: "i\(coin.imageUrl)", in: logoAnimation)
                
                Text("Receive \(coin.coinSymbol)")
                    .font(.custom("ZohoPuvi-SemiBold", size: 24))
            }
            
            Text("Scan or copy the address below")
                .font(.custom("ZohoPuvi-Medium", size: 18))
                .foregroundColor(.gray)
            
            
            if let address = address, let qrImage = generateQRCode(from: address) {
                Image(uiImage: qrImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(.top, 150)
                Text(address)
                    .font(.custom("ZohoPuvi-SemiBold", size: 22))
                
            } else {
                Text("Address Unavailable")
                    .font(.custom("ZohoPuvi-SemiBold", size: 16))
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Button(action: copyToClipboard) {
                Label("Copy Address", systemImage: "doc.on.doc")
                    .font(.custom("ZohoPuvi-SemiBold", size: 20))
                    .padding(10)
                    .padding(.horizontal, 20)
                    .background(address != nil ? .primaryTheme : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(address == nil)
            .padding(.top, -100)
            
        }
        .onAppear {
            self.address = "\(globalViewModel.session.username)_\(coin.id)"
        }
        
    }
    
    func copyToClipboard() {
        if let address {
            UIPasteboard.general.string = address
        }
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            let colorFilter = CIFilter.falseColor()
            colorFilter.inputImage = outputImage
            colorFilter.color0 = CIColor(color: .orange) // QR Code Color
            colorFilter.color1 = CIColor(color: .clear) // Background Color
            
            if let coloredImage = colorFilter.outputImage,
               let cgImage = context.createCGImage(coloredImage, from: coloredImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}

#Preview {
    ReceiveView(coin: CoinDetails(
        id: 1,
        coinName: "Bitcoin",
        coinSymbol: "BTC",
        imageUrl: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png?1547033579"
    ), logoAnimation: Namespace().wrappedValue)
}
