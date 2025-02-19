import SwiftUI
import Kingfisher

struct SendView: View {
    let userHolding: UserHolding
    @State var transferAddress: String = ""
    @State private var amount: String = ""
    @State private var isShowingScanner: Bool = false
    @State private var isConfirmingTransfer: Bool = false
    
    @Environment(\.globalViewModel) var globalViewModel
    var nameSpace: Namespace.ID
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView()
            
            // Coin Details
            coinDetailsView()
                .padding(.top, 20)
            
            VStack(spacing: 30){
                // Transfer Address Input
                addressInputView()
                
                    .onAppear {
                        if(globalViewModel.selectedCoin.coin.id != 0 && globalViewModel.selectedUser.username != ""){
                            transferAddress = (globalViewModel.selectedUser.username) + "_" +  String(globalViewModel.selectedCoin.coin.id)
                        }
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
            QRReaderView(scannedCode: $transferAddress)
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
                .font(.custom("ZohoPuvi-Bold", size: 32))
                .foregroundStyle(.font)
            Spacer()
        }
    }
    
    private func coinDetailsView() -> some View {
        HStack(spacing: 12) {
            SymbolWithNameView(coin: userHolding.coin, searchText: "", nameSpace: nameSpace)
            .padding(.leading, 10)
            
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
                .padding(.bottom, 10)
            
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
                .padding(.bottom, 10)
            
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
        Task{
            await WebSocketManager.shared.sendMessage(to: String(transferAddress.split(separator: "_")[0]), message: "@payment,\(globalViewModel.selectedCoin.coin.id),\(amount),\(transferAddress)")
        }
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
    ), nameSpace: Namespace().wrappedValue)
}
