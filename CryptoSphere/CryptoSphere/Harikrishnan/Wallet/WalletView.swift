//
//  WalletView.swift
//  Real app
//
//  Created by Harikrishnan V on 2025-02-06.
//

import SwiftUI

struct WalletView: View {
    
    @State private var balance: Double = 0
    @State private var coins: [UserHolding] = []
    @State private var searchText: String = ""
    @State private var searchTextsheet: String = ""
    @State private var isSendActionSheetPresented = false
    @State private var isReceiveActionSheetPresented = false
    @Environment(GlobalViewModel.self) private var globalViewModel
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                walletData()
                    .onAppear { fillcoins() }
                UserCoinListView(coins: coins, allowSelection: false, navigationDestination: { _ in AnyView(Text(""))})
                Spacer()
            }
            .refreshable { fillcoins() }
        }
        .padding()
        .navigationTitle("Wallet")
    }
    
    func walletData() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wallet.bifold")
                    .font(.title2)
                Text("Your Balance")
                    .font(.headline)
            }
            
            Text("\(balance, format: .currency(code: "USD"))")
                .font(.title)
                .bold()
                .padding()
            
            HStack(spacing: 16) {
                Button(action: { isSendActionSheetPresented = true }) {
                    HStack {
                        Image(systemName: "paperplane")
                        Text("Send")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.black.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: { isReceiveActionSheetPresented = true }) {
                    HStack {
                        Image(systemName: "arrow.down.to.line.alt")
                        Text("Receive")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.black.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .sheet(isPresented: $isSendActionSheetPresented) {
            UserCoinListView(coins: coins, allowSelection: true, navigationDestination: { coin in AnyView(SendView(userHolding: coin as! UserHolding)) })
                .padding()
            .presentationDragIndicator(.visible)
            .navigationTitle("Select Coin to Receive")
        }
        
        .sheet(isPresented: $isReceiveActionSheetPresented) {
            AllCoinsListView(
                onSelectCoin: { coin in AnyView(ReceiveView(coin: coin )) }
            )
            .presentationDragIndicator(.visible)
        }
        
    }
    
    func fillcoins(){
        Task {
            balance = 0.0
            do {
                coins = try await ServerResponce.shared.fetchuserholdings(userName: globalViewModel.session.username)
                for i in coins{
                    let price = try await LivePriceResponse().fetchPrice(coinName: i.coin.coinSymbol).result.list[0].lastPrice
                    balance += i.quantity * (Double(price) ?? 0)
                    
                }
            } catch {
                print("Failed to fetch coins: \(error.localizedDescription)")
            }
            animateBalanceUpdate(to: balance)
        }
    }
    

    
    func animateBalanceUpdate(to newBalance: Double) {
        let duration: Double = 2
        let steps = 50
        let stepInterval = duration / Double(steps)
        
        var currentStep = 0
        let startBalance = balance
        
        // Timer to animate the balance update smoothly over steps
        Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { timer in
            let progress = Double(currentStep) / Double(steps)
            balance = startBalance + (newBalance - startBalance) * progress
            currentStep += 1
            
            if currentStep > steps {
                timer.invalidate()
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search coins", text: $text)
                .font(.system(.body, design: .rounded))
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 5, y: 3)
    }
}

struct UserCoinListView: View {
    @Environment(GlobalViewModel.self) private var globalViewModel
    @State var searchText: String = ""
    
    let coins: [UserHolding]
    let allowSelection: Bool
    let navigationDestination: (Any) -> AnyView
    
    var filteredCoins: [UserHolding] {
        if searchText.isEmpty {
            return coins
        } else {
            return coins.filter { $0.coin.coinName.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack{
            SearchBar(text: $searchText)
            
            if filteredCoins.isEmpty {
                ContentUnavailableView(
                    "No cryptocurrencies found",
                    systemImage: "bitcoinsign.circle.fill"
                )
                .foregroundColor(.gray)
            } else{
                ScrollView {
                    LazyVStack {
                        ForEach(filteredCoins, id: \.self) { coin in
                            if allowSelection {
                                NavigationLink(destination: navigationDestination(coin)) {
                                    coinRow(coin)
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    globalViewModel.selectedCoin = coin
                                })
                            }
                            else{
                                coinRow(coin)
                            }
                        }
                    }
                }
                .navigationDestination(for: UserHolding.self) { coin in
                    Text(coin.email)
                }
            }
        }
    }
    
    func coinRow(_ coin: UserHolding) -> some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: coin.coin.imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable()
                case .failure:
                    Image(systemName: "bitcoinsign.circle.fill")
                        .resizable()
                        .foregroundColor(.secondary)
                @unknown default:
                    EmptyView()
                }
            }
            .scaledToFit()
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(coin.coin.coinName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(coin.coin.coinSymbol.uppercased())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Quantity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(coin.quantity, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .bold()
                
            }
            .padding(.leading, 8)
        }
        
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}


#Preview {
    NavigationStack {
        WalletView()
            .environment(GlobalViewModel())
    }
}
