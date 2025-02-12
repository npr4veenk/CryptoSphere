import SwiftUI
import CoreImage.CIFilterBuiltins

struct ReceiveView: View {
    let coin: CoinDetails
    @State private var address: String?
    @State private var isLoading = true
    @Environment(GlobalViewModel.self) var globalViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 4) {
                Text("Receive \(coin.coinSymbol)")
                    .font(.system(size: 24, weight: .semibold))
                
                Text("Scan or copy the address")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 24)
            
            // QR Code
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.background.opacity(0.0))
                    .frame(width: 240, height: 240)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                
                if isLoading {
                    ProgressView()
                } else if let address = address {
                    VStack(spacing: 12) {
                        Image(uiImage: generateQRCode(from: address))
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 200, height: 200)
                        
                        Text(address)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(.horizontal, 8)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 32))
                        Text("Address unavailable")
                            .font(.subheadline)
                    }
                    .foregroundColor(.red)
                }
            }
            .padding(.vertical, 16)
            
            // Copy Button
            Button(action: copyToClipboard) {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Address")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.gradient)
                .cornerRadius(12)
            }
            .disabled(address == nil)
            .opacity(address == nil ? 0.5 : 1)
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .task { await getAddress() }
    }
    
    private func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            // Create color filter to tint the QR code
            let colorFilter = CIFilter(name: "CIFalseColor")!
            colorFilter.setValue(outputImage, forKey: "inputImage")
            colorFilter.setValue(CIColor(color: UIColor.blue), forKey: "inputColor0")
            colorFilter.setValue(CIColor(color: UIColor.background), forKey: "inputColor1")
            if let coloredOutput = colorFilter.outputImage,
               let cgImage = context.createCGImage(coloredOutput, from: coloredOutput.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    func getAddress() async {
        do {
            let fetchedAddress = try await ServerResponce.shared.fetchCoinAddresses(
                userName: globalViewModel.session.username,
                coinId: coin.id
            )
            DispatchQueue.main.async {
                self.address = fetchedAddress
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.address = nil
                self.isLoading = false
            }
            print("Error fetching address: \(error)")
        }
    }
    
    func copyToClipboard() {
        if let address {
            UIPasteboard.general.string = address
        }
    }
}

#Preview {
    ReceiveView(coin: CoinDetails(
        id: 1,
        coinName: "Bitcoin",
        coinSymbol: "BTC",
        imageUrl: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png?1547033579"
    ))
    .environment(GlobalViewModel())
}
