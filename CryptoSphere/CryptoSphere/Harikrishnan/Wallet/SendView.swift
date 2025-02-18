import SwiftUI

struct SendView: View {
    let userHolding: UserHolding
    @State private var transferAddress: String = ""
    @State private var amount: String = ""
    @State private var isShowingScanner: Bool = false
    @State private var isConfirmingTransfer: Bool = false
    
    @Environment(\.globalViewModel) var globalViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView()
            
            // Coin Details
            coinDetailsView()
            
            // Transfer Address Input
            addressInputView()
            
            // Amount Input
            amountInputView()
            
            // Confirm Button
            confirmButton()
            Spacer()
        }
        .padding()
        .background(Color.background)
        .sheet(isPresented: $isShowingScanner) {
            QRCodeScannerView { code in
                transferAddress = code
                isShowingScanner = false
            }
        }
        .alert("Confirm Transfer", isPresented: $isConfirmingTransfer) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm", role: .destructive) {
                Task{
                    await confirmTransfer()
                }
            }
        } message: {
            Text("Are you sure you want to transfer \(amount) \(userHolding.coin.coinSymbol) to \(transferAddress)?")
        }
    }
    
    // MARK: - Subviews
    
    private func headerView() -> some View {
        HStack {
            Text("Send \(userHolding.coin.coinSymbol)")
                .font(.title2.bold())
                .foregroundStyle(.font)
            Spacer()
        }
    }
    
    private func coinDetailsView() -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: userHolding.coin.imageUrl)) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(userHolding.coin.coinName)
                    .font(.headline)
                    .foregroundStyle(.font)
                
                Text(userHolding.coin.coinSymbol)
                    .font(.subheadline)
                    .foregroundStyle(.secondaryFont)
                
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func addressInputView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recipient Address")
                .font(.subheadline)
                .foregroundStyle(.font)
            
            HStack {
                TextField("Enter wallet address", text: $transferAddress)
                    .autocapitalization(.none)
                    .foregroundStyle(.secondaryFont)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Button(action: { isShowingScanner = true }) {
                    Image(systemName: "qrcode.viewfinder")
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundStyle(.orange.gradient)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private func amountInputView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.subheadline)
                .foregroundStyle(.font)
            
            TextField("0", text: $amount)
                .keyboardType(.decimalPad)
                .foregroundStyle(.secondaryFont)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .onChange(of: amount) { _ ,newValue in
                    amount = newValue.filter { "0123456789.".contains($0) }
                }
            
            Text("Available: \(userHolding.quantity, specifier: "%.4f") \(userHolding.coin.coinSymbol)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private func confirmButton() -> some View {
        Button(action: { isConfirmingTransfer = true }) {
            Text("Confirm Transfer")
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange.gradient)
                .foregroundColor(.font)
                .cornerRadius(12)
        }
        .disabled(transferAddress.isEmpty || amount.isEmpty || (Double(amount) ?? 0) > userHolding.quantity)
        .opacity(transferAddress.isEmpty || (Double(amount) ?? 0) > userHolding.quantity ? 0.6 : 1)
    }
    
    // MARK: - Actions
    
    private func confirmTransfer() async {
        print("Transferring \(amount) \(userHolding.coin.coinSymbol) to \(transferAddress)")
        
        
        await globalViewModel.wsManager.sendMessage(to: " ", message: "@payment,\(globalViewModel.selectedCoin.coin.id),\(amount),\(transferAddress)")
    }
}

// MARK: - QR Code Scanner View

struct QRCodeScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let scannerVC = ScannerViewController()
        scannerVC.onScan = onScan
        return scannerVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

class ScannerViewController: UIViewController {
    var onScan: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Implement QR code scanning logic here
    }
}

// MARK: - Preview

#Preview {
    SendView(userHolding: UserHolding(
        email: "",
        coin: CoinDetails(
            id: 1,
            coinName: "Bitcoin",
            coinSymbol: "BTC",
            imageUrl: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png"
        ),
        quantity: 0.5
    ))
}
