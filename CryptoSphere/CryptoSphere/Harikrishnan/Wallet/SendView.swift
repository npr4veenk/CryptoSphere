import SwiftUI

struct SendView: View {
    let userHolding: UserHolding
    @State var transferAddress: String = ""
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
                .padding(.top, 40)
            
            VStack(spacing: 30){
                // Transfer Address Input
                addressInputView()
                
                    .onAppear {
                        if(globalViewModel.selectedCoin.coin.id != 0 && globalViewModel.selectedUser.username != ""){
                            setUpAddress()
                        }
                    }
                    .onDisappear {
                        globalViewModel.selectedCoin = UserHolding(email: "", coin: CoinDetails(id: 0, coinName: "", coinSymbol: "", imageUrl: ""), quantity: 2)
                        
                        globalViewModel.selectedUser = User(email: "", username: "", password: "", profilePicture: "")
                    }
                
                // Amount Input
                amountInputView()
            }.padding(.top, 40)
            
            // Confirm Button
            confirmButton()
                .padding(.top, 40)
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
    
    func setUpAddress() {
        Task{
            let UserId = try? await JSONDecoder().decode([String: String].self, from: URLSession.shared.data(from: URL(string: "https://cryptospyer.loca.lt/get_user/\(globalViewModel.selectedUser.username)")!).0)["id"] ?? ""
            
            transferAddress = (UserId ?? "") + "_" +  String(globalViewModel.selectedCoin.coin.id)
        }
    }
    
    // MARK: - Subviews
    
    private func headerView() -> some View {
        HStack {
            Text("Send \(userHolding.coin.coinSymbol)")
                .font(.custom("ZohoPuvi-Bold", size: 32))
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
                    .font(.custom("ZohoPuvi-Semibold", size: 22))
                    .foregroundStyle(.font)
                
                Text(userHolding.coin.coinSymbol)
                    .font(.custom("ZohoPuvi-Semibold", size: 16))
                    .foregroundStyle(.secondaryFont)
                
            }
            Spacer()
        }
        .padding()
        .background(Color("GrayButtonColor"))
        .cornerRadius(12)
    }
    
    private func addressInputView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recipient Address")
                .font(.custom("ZohoPuvi-Semibold", size: 20))
                .foregroundStyle(.font)
            
            HStack {
                TextField("Enter wallet address", text: $transferAddress)
                    .font(.custom("ZohoPuvi-Semibold", size:18))
                    .autocapitalization(.none)
                    .foregroundStyle(.secondaryFont)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color("GrayButtonColor"))
                    .cornerRadius(8)
                
                Button(action: { isShowingScanner = true }) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 35))
                        .padding(6)
                        .background(Color("GrayButtonColor"))
                        .foregroundStyle(Color("primaryTheme"))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private func amountInputView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.custom("ZohoPuvi-Semibold", size: 20))
                .foregroundStyle(.font)
            
            TextField("0", text: $amount)
                .keyboardType(.decimalPad)
                .foregroundStyle(.secondaryFont)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(10)
                .background(Color("GrayButtonColor"))
                .cornerRadius(12)
                .onChange(of: amount) { _ ,newValue in
                    amount = newValue.filter { "0123456789.".contains($0) }
                }
            
            Text("Available: \(userHolding.quantity, specifier: "%.4f") \(userHolding.coin.coinSymbol)")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
    
    private func confirmButton() -> some View {
        Button(action: { isConfirmingTransfer = true }) {
            Text("Confirm Transfer")
                .font(.custom("ZohoPuvi-Bold", size: 22))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("primaryTheme"))
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
