import SwiftUI
import CoreImage.CIFilterBuiltins
import Kingfisher

struct ReceiveView: View {
    let coin: CoinDetails
    @State var address: String?
    @State private var isCopied = false
    @Environment(\.globalViewModel) var globalViewModel
    var logoAnimation: Namespace.ID
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                KFImage(URL(string: coin.imageUrl))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .matchedGeometryEffect(id: "i\(coin.imageUrl)", in: logoAnimation)
                
                VStack(spacing: 4) {
                    Text("Receive \(coin.coinSymbol.uppercased())")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Scan the QR code or copy address below")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 32)
            
            // QR Code
            if let address = address, let qrImage = generateQRCode(from: address) {
                Image(uiImage: qrImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    .transition(.scale.combined(with: .opacity))
            } else {
                ProgressView()
                    .controlSize(.large)
            }
            
            // Address
            if let address = address {
                VStack(spacing: 16) {
                    Text(address)
                        .font(.system(.callout, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .transition(.opacity)
                    
                    Button {
                        copyToClipboard()
                    } label: {
                        HStack {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            Text(isCopied ? "Copied" : "Copy Address")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isCopied ? .green : .blue)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isCopied ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut) {
                self.address = "\(globalViewModel.session.username)_\(coin.id)"
            }
        }
    }
    
    func copyToClipboard() {
        guard let address else { return }
        
        UIPasteboard.general.string = address
        isCopied = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                isCopied = false
            }
        }
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "Q"
        
        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
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
