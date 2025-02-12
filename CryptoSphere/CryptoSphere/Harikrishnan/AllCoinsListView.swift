//
//  UsersListView 2.swift
//  Real app
//
//  Created by Harikrishnan V on 2025-02-06.
//


import SwiftUI

struct AllCoinsListView: View {
    
    @State private var searchText: String = ""
    @State private var coins: [CoinDetails] = []
    @State private var isLoading: Bool = false
    
    @Namespace private var animation
    
    var onSelectCoin: (CoinDetails) -> AnyView
    
    var filteredCoins: [CoinDetails] {
        searchText.isEmpty ? coins : coins.filter { $0.coinSymbol.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            if isLoading {
                Spacer()
                ProgressView("Loading coins...")
                Spacer()
            } else if coins.isEmpty {
                ContentUnavailableView("No coins Found", systemImage: "person.2.slash")
            } else {
                ScrollView{
                    LazyVStack(alignment: .leading, spacing: 16){
                        ForEach(filteredCoins, id: \.self) { coin in
                            NavigationLink {
                                onSelectCoin(coin)
                            } label: {
                                HStack(spacing: 16) {
                                    AsyncImage(url: URL(string: coin.imageUrl)) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                        case .success(let image):
                                            image.resizable()
                                        case .failure:
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(.secondary)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
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
                            Divider()
                                .background(.primary)
                        }
                    }
                }
                .padding()
                .animation(.easeInOut(duration: 0.3), value: filteredCoins)
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
                coins = try await CoinDetailsResponse().fetchAllCoinDetails()
            } catch {
                print("Failed to fetch coins: \(error.localizedDescription)")
            }
        }
    }
    
    private func highlightedUsername(_ username: String) -> Text {
        guard let range = username.lowercased().range(of: searchText.lowercased()) else {
            return Text(username)
        }
        
        let before = Text(String(username[..<range.lowerBound]))
        let highlighted = Text(String(username[range])).foregroundColor(.blue)
        let after = Text(String(username[range.upperBound...]))
        
        return before + highlighted + after
    }
}

#Preview {
    AllCoinsListView(onSelectCoin: { coin in
        AnyView(ReceiveView(coin: coin))
    })
}
