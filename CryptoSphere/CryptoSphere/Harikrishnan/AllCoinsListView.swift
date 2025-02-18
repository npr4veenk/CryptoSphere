//
//  UsersListView 2.swift
//  Real app
//
//  Created by Harikrishnan V on 2025-02-06.
//


import SwiftUI
import Kingfisher


struct AllCoinsListView: View {
    
    var isUserHoldingCoins: Bool
    
    @State private var searchText: String = ""
    @State private var coins: [CoinDetails] = []
    @State private var userHoldings: [UserHolding] = []
    @State private var coinValues: [String: Double] = [:]
    @State private var isLoading: Bool = false
    
    @Namespace private var animation
    @Environment(\.globalViewModel) var globalViewModel
    
    var onSelectCoin: (Any) -> AnyView
    
    var filteredCoins: [CoinDetails] {
        searchText.isEmpty ? coins : coins.filter { $0.coinSymbol.localizedCaseInsensitiveContains(searchText) }
    }
    
    var filteredUserHolding: [UserHolding] {
        searchText.isEmpty ? userHoldings : userHoldings.filter { $0.coin.coinSymbol.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        
        NavigationStack {
            if isLoading {
                Spacer()
                ProgressView("Loading coins...")
                Spacer()
            } else if coins.isEmpty && userHoldings.isEmpty {
                ContentUnavailableView("No coins Found", systemImage: "person.2.slash")
            } else {
                ScrollView{
                    LazyVStack(alignment: .leading, spacing: 16){
                        if isUserHoldingCoins{
                            ForEach(filteredUserHolding, id: \.self) { userHolding in
                                NavigationLink {
                                    onSelectCoin(userHolding)
                                        .onAppear {
                                            globalViewModel.selectedCoin = userHolding
                                        }
                                } label: {
                                    HStack {
                                        SymbolWithNameView(coin: userHolding.coin, searchText: $searchText)
                                        
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 8) {
                                            Spacer()
                                            HStack {
                                                Text("Quantity :")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                
                                                Text(String(format: "%.2f", userHolding.quantity ))
                                                    .font(.caption)
                                                    .foregroundColor(.primary)
                                            }
                                            HStack(spacing: 2) {
                                                Text("$ ")
                                                    .foregroundStyle(.primary)
                                                Text(String(format: "%.2f", (userHolding.quantity * (coinValues[userHolding.coin.coinSymbol] ?? 0.0))))
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                
                                Divider()
                                    .background(Color("primaryTheme"))
                            }
                        } else {
                            ForEach(filteredCoins, id: \.self) { coin in
                                NavigationLink {
                                    onSelectCoin(coin)
                                } label: {
                                    SymbolWithNameView(coin: coin, searchText: $searchText)
                                        .padding(.horizontal)
                                }
                                Divider()
                                    .background(Color("primaryTheme"))
                            }
                        }
                    }
                }
                .padding(8)
                .animation(.easeInOut(duration: 0.3), value: filteredCoins)
                .animation(.easeInOut(duration: 0.3), value: filteredUserHolding)
                .refreshable {
                    fetchCoins()
                }
            }
        }
        .navigationTitle("Coins")
        .searchable(text: $searchText, prompt: "Search coins")
        .onAppear { fetchCoins() }
    }
    
    private func fetchCoins() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                if isUserHoldingCoins{
                    userHoldings = try await ServerResponce.shared.fetchuserholdings(userName: globalViewModel.session.username)
                    
                   for userHolding in userHoldings {

                        coinValues[userHolding.coin.coinSymbol] = await getPrice(coinSymbol: userHolding.coin.coinSymbol)
                    }
                } else {
                    coins = try await ServerResponce.shared.fetchAllCoinDetails()
                }
            } catch {
                print("Failed to fetch coins: \(error.localizedDescription)")
            }
        }
    }
    
    private func getPrice(coinSymbol: String) async -> Double {
        do {
            return try await Double(LivePriceResponse().fetchPrice(coinName: coinSymbol).result.list[0].lastPrice) ?? 0.0
        } catch {
            print("Error fetching price: \(error)")
            return 0.0
        }
    }
    
}


struct SymbolWithNameView: View {
    
    var coin: CoinDetails
    @Binding var searchText: String
    
    var body: some View {
        HStack(spacing: 16) {
            KFImage(URL(string: coin.imageUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                highlightedUsername(coin.coinSymbol)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(coin.coinName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .transition(.slide)
    }
    
    private func highlightedUsername(_ username: String) -> Text {
        guard let range = username.lowercased().range(of: searchText.lowercased()) else {
            return Text(username)
        }
        
        let before = Text(String(username[..<range.lowerBound]))
        let highlighted = Text(String(username[range])).foregroundColor(Color("primaryTheme"))
        let after = Text(String(username[range.upperBound...]))
        
        return before + highlighted + after
    }

}

#Preview {
//    AllCoinsListView(
//        isUserHoldingCoins: false,
//        onSelectCoin: { coin in
//            AnyView(ReceiveView(coin: coin as! CoinDetails))
//        }
//    )
    
    AllCoinsListView(
        isUserHoldingCoins: true,
        onSelectCoin: { userHolding in
            AnyView(SendView(userHolding: userHolding as! UserHolding))
        }
    )
}

