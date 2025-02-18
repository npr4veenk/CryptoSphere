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
    @Environment(\.globalViewModel) private var globalViewModel
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                walletData()
                    .onAppear { fillcoins() }
                AllCoinsListView(isUserHoldingCoins: true, onSelectCoin: { userHolding in
                    AnyView(SendView(userHolding: userHolding as! UserHolding))
                })
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
                    .background(Color("primaryTheme"))
                    .foregroundColor(.font)
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
            AllCoinsListView(isUserHoldingCoins: true, onSelectCoin: { userHolding in
                AnyView(SendView(userHolding: userHolding as! UserHolding))
            })
            .padding()
            .presentationDragIndicator(.visible)
            .navigationTitle("Select Coin to Receive")
        }
        
        .sheet(isPresented: $isReceiveActionSheetPresented) {
            AllCoinsListView(isUserHoldingCoins: true, onSelectCoin: { userHolding in
                AnyView(SendView(userHolding: userHolding as! UserHolding))
            })
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
                animateBalanceUpdate(to: balance)
            } catch {
                print("Failed to fetch coins: \(error.localizedDescription)")
            }
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


#Preview {
    NavigationStack {
        WalletView()
    }
}

