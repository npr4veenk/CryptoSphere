import SwiftUI
import Kingfisher

struct SendView: View {
    let userHolding: UserHolding
    @State var transferAddress: String = ""
    @State private var amount: String = ""
    @State private var isShowingScanner: Bool = false
    @State private var isConfirmingTransfer: Bool = false
    @State private var isProcessing: Bool = false
    @FocusState private var isAmountFocused: Bool
    
    @Environment(\.globalViewModel) var globalViewModel
    var nameSpace: Namespace.ID
    
    @Environment(\.dismiss) var dismiss
    @State private var completion: Bool? = nil
    @State private var completionmsg: String = ""
    
    var body: some View {
        ZStack{
            
            VStack(spacing: 0) {
                // Header
                headerView()
                    .padding(.bottom, 32)
                
                // Main Content
                ScrollView {
                    VStack(spacing: 32) {
                        // Coin Card
                        coinCardView()
                        
                        // Input Sections
                        inputSections()
                    }
                    .padding(.horizontal)
                }
                
                // Confirm Button
                confirmButton()
                    .padding()
            }
            
            if let Completion = completion {
                TransactionStatusView(
                    status: Completion ?
                        .success(amount: Double(amount) ?? 0.0, recipient: transferAddress) :
                        .error(message: completionmsg),
                    onDismiss: {dismiss()},
                    onRetry: {completion = nil})
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $isShowingScanner) {
            QRReaderView(scannedCode: $transferAddress)
                .accentColor(.primaryTheme)
        }
        .alert("Confirm Transfer", isPresented: $isConfirmingTransfer) {
            transferConfirmationDialog()
        } message: {
            Text(
            """
            
            You are about to send:
            \(amount) \(userHolding.coin.coinSymbol.uppercased())
            
            To address:
            \(transferAddress)
            """
            )
        }
        .onAppear {
            if globalViewModel.selectedCoin.coin.id != 0 && !globalViewModel.selectedUser.username.isEmpty {
                transferAddress = "\(globalViewModel.selectedUser.username)_\(globalViewModel.selectedCoin.coin.id)"
            }
        }
    }
    
    // MARK: - Subviews
    
    private func headerView() -> some View {
        HStack {
            Text("Send Crypto")
                .font(.system(.title2, design: .rounded, weight: .medium))
                .foregroundColor(.primaryTheme)
            
            Spacer()
            
//            Button {
//                // Close action
//                dismiss()
//            } label: {
//                Image(systemName: "xmark.circle.fill")
//                    .font(.system(size: 28))
//                    .foregroundColor(.secondary)
//            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    private func coinCardView() -> some View {
        HStack(spacing: 16) {
            KFImage(URL(string: userHolding.coin.imageUrl))
                .resizable()
                .matchedGeometryEffect(id: "i\(userHolding.coin.imageUrl)", in: nameSpace)
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(userHolding.coin.coinName)
                    .matchedGeometryEffect(id: "cn\(userHolding.coin.coinName)", in: nameSpace)
                    .font(.system(.title3, weight: .semibold))
                
                Text(userHolding.coin.coinSymbol.uppercased())
                    .matchedGeometryEffect(id: "cs\(userHolding.coin.coinSymbol)", in: nameSpace)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(userHolding.quantity, specifier: "%.4f")")
                    .font(.system(.body, design: .monospaced, weight: .medium))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private func inputSections() -> some View {
        VStack(spacing: 24) {
            // Recipient Address
            VStack(alignment: .leading, spacing: 12) {
                Label("Recipient Address", systemImage: "wallet.pass")
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Address or ENS", text: $transferAddress)
                        .font(.system(.body, design: .monospaced))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textContentType(.URL)
                    
                    Button {
                        isShowingScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                            .symbolVariant(.circle.fill)
                            .font(.system(size: 24))
                            .foregroundColor(.primaryTheme)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.systemGray5), lineWidth: 1)
                )
            }
            
            // Amount Input
            VStack(alignment: .leading, spacing: 12) {
                Label("Amount to Send", systemImage: "dollarsign.circle")
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("0", text: $amount)
                        .focused($isAmountFocused)
                        .font(.system(size: 40, weight: .bold, design: .default))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .foregroundColor(isAmountFocused ? .primary : .secondary)
                        .overlay(alignment: .trailing) {
                            Text(userHolding.coin.coinSymbol.uppercased())
                                .font(.system(.title3, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.trailing)
                        }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isAmountFocused ? Color.primaryTheme : Color(.systemGray5), lineWidth: 1)
                )
                .onChange(of: amount) { _, newValue in
                    let filtered = newValue.filter { "0123456789.".contains($0) }
                    let components = filtered.components(separatedBy: ".")
                    if components.count > 2 {
                        amount = String(filtered.dropLast())
                    } else {
                        amount = filtered
                    }
                }
            }
        }
    }
    
    private func confirmButton() -> some View {
        Button {
            isConfirmingTransfer = true
        } label: {
            HStack {
                if isProcessing {
                    ProgressView()
                        .transition(.opacity)
                }
                Text(isProcessing ? "Processing..." : "Review Transfer")
                    .font(.system(.headline, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: [Color.primaryTheme, Color.primaryTheme.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(12)
            )
            .foregroundColor(.white)
        }
        .disabled(!isFormValid)
        .opacity(isFormValid ? 1 : 0.6)
    }
    
    // MARK: - Helpers
    
    private var isFormValid: Bool {
        !transferAddress.isEmpty &&
        !amount.isEmpty &&
        (Double(amount) ?? 0 <= userHolding.quantity &&
        (Double(amount) ?? 0) > 0)
    }
    
    private func transferConfirmationDialog() -> some View {
        Group {
            Button("Cancel", role: .cancel) {}
            Button("Confirm Transfer", role: .destructive) {
                Task {
                    isProcessing = true
                    await confirmTransfer()
                    isProcessing = false
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func confirmTransfer() async {
        await WebSocketManager.shared.sendMessage(
            to: String(transferAddress.split(separator: "_")[0]),
            message: "@payment,\(globalViewModel.selectedCoin.coin.id),\(amount),\(transferAddress)"
        ) { status, msg in
            print("SUCCESS \(status)")
            completionmsg = msg
            completion = status
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
        quantity: 10.5
    ), nameSpace: Namespace().wrappedValue)
}
