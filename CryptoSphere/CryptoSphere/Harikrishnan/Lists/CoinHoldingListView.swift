//
//  UsersListView 2.swift
//  Real app
//
//  Created by Harikrishnan V on 2025-02-06.
//

import SwiftUI
import Kingfisher
import SwiftData

struct CoinHoldingListView: View {
    
    @State private var userHoldings: [UserHolding] = []
    @State private var coinValues: [String: Double] = [:]
    @State private var searchText: String = ""
    @State private var isLoading = false
    
    @Namespace var nameSpace
    @Environment(\.globalViewModel) var globalViewModel
    
    @State var selectedCoin: UserHolding? = nil
    
    var hasNavigate: Bool
    
    var filteredUserHolding: [UserHolding] {
        searchText.isEmpty ? userHoldings : userHoldings.filter { $0.coin.coinSymbol.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ZStack{
            ScrollView {
                LazyVStack {
                    ForEach(filteredUserHolding, id: \.self) { userHolding in
                        HStack {
                            SymbolWithNameView(coin: userHolding.coin, searchText: searchText, nameSpace: nameSpace)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 8) {
                                
                                HStack(spacing:1){
                                    Text("$ ")
                                        .foregroundStyle(.primary)
                                    Text(String(format: "%.2f", (userHolding.quantity * (coinValues[userHolding.coin.coinSymbol] ?? 0.0))))
                                        .foregroundColor(.primary)
                                }
                                .font(.custom("ZohoPuvi-Semibold", size: 19))

                                HStack {
                                    Text("Units:")
                                        .foregroundColor(.secondary)
                                    
                                    Text(String(format: "%.2f", userHolding.quantity ))
                                        .foregroundColor(.primary)
                                }
                                .font(.custom("ZohoPuvi-Medium", size: 14))

                            }
                            .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            globalViewModel.selectedCoin = userHolding
                            withAnimation() {
                                selectedCoin = userHolding
                            }
                        }
                        .background(Color("GrayButtonColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: userHoldings)
            }
            .padding()
            .onAppear {
                fetchCoins()
            }
            
            if let selectedCoin = selectedCoin, hasNavigate {
                NavigationStack{
                    SendView(userHolding: selectedCoin, nameSpace: nameSpace)
                        .zIndex(1)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Back") {
                                    withAnimation {
                                        self.selectedCoin = nil
                                    }
                                }
                            }
                        }
                }
            }
        }
    }
    
    private func fetchCoins() {
        isLoading = true
        Task {
            defer { isLoading = false }
            userHoldings = try await ServerResponce.shared.fetchuserholdings()
            
            for userHolding in userHoldings {
                coinValues[userHolding.coin.coinSymbol] = await getPrice(coinSymbol: userHolding.coin.coinSymbol)
            }
        }
    }
    
    private func getPrice(coinSymbol: String) async -> Double {
        do {
            return try await Double(fetchPrice(coinName: coinSymbol).result.list[0].lastPrice) ?? 0.0
        } catch {
            print("Error fetching price: \(error)")
            return 0.0
        }
    }
    
}

struct SymbolWithNameView: View {
    
    var coin: CoinDetails
    @State var searchText: String
    var nameSpace: Namespace.ID
    
    var body: some View {
        HStack(spacing: 16) {
            KFImage(URL(string: coin.imageUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .background(.white)
                .clipShape(Circle())
                .matchedGeometryEffect(id: "i\(coin.imageUrl)", in: nameSpace)
            
            
            VStack(alignment: .leading, spacing: 4) {
                highlightedUsername(coin.coinName)
                    .matchedGeometryEffect(id: "cn\(coin.coinName)", in: nameSpace)
                    .font(.custom("ZohoPuvi-Semibold", size: 19))
                    .foregroundColor(.primary)
                highlightedUsername(coin.coinSymbol)
                    .matchedGeometryEffect(id: "cs\(coin.coinSymbol)", in: nameSpace)
                    .font(.custom("ZohoPuvi-Semibold", size: 14))
                    .foregroundColor(.secondary)
            }

        }
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
    CoinHoldingListView(hasNavigate: true)
}
