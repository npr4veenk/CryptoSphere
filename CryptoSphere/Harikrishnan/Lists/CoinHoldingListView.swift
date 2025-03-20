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
    
    var hasNavigate: Bool = false
    
    @Namespace var nameSpace
    @Environment(\.globalViewModel) var globalViewModel
    
    @State var selectedCoin: UserHolding? = nil
    
    var filteredUserHolding: [UserHolding] {
        searchText.isEmpty ? userHoldings : userHoldings.filter { $0.coin.coinSymbol.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .transition(.opacity)
            } else {
                contentView
                    .padding()
            }
            
            if let selectedCoin = selectedCoin, hasNavigate {
                SendView(userHolding: selectedCoin, nameSpace: nameSpace)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear(perform: fetchCoins)
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                SearchBar(text: $searchText)
                
                ForEach(filteredUserHolding, id: \.self) { userHolding in
                    CoinRow(userHolding: userHolding)
                        .onTapGesture(perform: { selectCoin(userHolding) })
                        .transition(.slide)
                }
            }
            .padding(.top)
        }
    }
    
    private func selectCoin(_ userHolding: UserHolding) {
        withAnimation(.spring()) {
            globalViewModel.selectedCoin = userHolding
            selectedCoin = userHolding
        }
    }
    
    private func CoinRow(userHolding: UserHolding) -> some View {
        HStack(spacing: 16) {
            CoinIconView(coin: userHolding.coin)
            
            VStack(alignment: .leading, spacing: 6) {
                HighlightedText(
                    text: userHolding.coin.coinName,
                    highlight: searchText,
                    highlightedFont: .subheadline.weight(.semibold),
                    normalFont: .subheadline
                )
                
                HighlightedText(
                    text: userHolding.coin.coinSymbol,
                    highlight: searchText,
                    highlightedColor: .primaryTheme,
                    normalColor: .secondary
                )
                .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            ValueColumn(userHolding: userHolding)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .matchedGeometryEffect(id: userHolding.coin.id, in: nameSpace)
    }
    
    private func ValueColumn(userHolding: UserHolding) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(userHolding.valueString(using: coinValues))
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
            
            HStack(spacing: 4) {
                Text("Qty:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(userHolding.quantity.formatted(.number.precision(.fractionLength(2))))
                    .font(.caption.monospacedDigit())
            }
        }
    }
    
    struct CoinIconView: View {
        let coin: CoinDetails
        @Namespace var nameSpace
        
        var body: some View {
            KFImage(URL(string: coin.imageUrl))
                .resizable()
                .placeholder {
                    ProgressView()
                        .frame(width: 44, height: 44)
                }
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .background(
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .matchedGeometryEffect(id: "i\(coin.imageUrl)", in: nameSpace)
        }
    }

    struct HighlightedText: View {
        let text: String
        let highlight: String
        var highlightedColor: Color = .primaryTheme
        var normalColor: Color = .primary
        var highlightedFont: Font = .subheadline
        var normalFont: Font = .subheadline
        
        var body: some View {
            Text(attributedString)
        }
        
        private var attributedString: AttributedString {
            var result = AttributedString(text)
            
            // Apply normal styles to the entire string first
            result.font = normalFont
            result.foregroundColor = normalColor
            
            // If highlight is empty, return the string with normal styles
            guard !highlight.isEmpty else { return result }
            
            // Convert the text and highlight to lowercase for case-insensitive search
            let lowercaseText = text.lowercased()
            let lowercaseHighlight = highlight.lowercased()
            
            var searchRange = lowercaseText.startIndex..<lowercaseText.endIndex
            
            // Find all ranges of the highlight text
            while let range = lowercaseText.range(
                of: lowercaseHighlight,
                options: .caseInsensitive,
                range: searchRange,
                locale: nil
            ) {
                // Convert the range to the original string's indices
                let nsRange = NSRange(range, in: text)
                if let attributedRange = Range(nsRange, in: result) {
                    // Apply highlighted styles to the matched range
                    result[attributedRange].foregroundColor = highlightedColor
                    result[attributedRange].font = highlightedFont
                }
                
                // Move the search range forward
                searchRange = range.upperBound..<lowercaseText.endIndex
            }
            
            return result
        }
    }

    struct SearchBar: View {
        @Binding var text: String
        
        var body: some View {
            HStack {
                TextField("Search coins", text: $text)
                    .padding(10)
                    .padding(.horizontal, 24)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .overlay(
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 8)
                        }
                    )
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    
    private func fetchCoins() {
        isLoading = true
        Task {
            defer { isLoading = false }
            userHoldings = try await ServerResponce.shared.fetchUserHoldings()
            
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
                .clipShape(Circle())
                .matchedGeometryEffect(id: "i\(coin.imageUrl)", in: nameSpace)
            
            
            VStack(alignment: .leading, spacing: 4) {
                highlightedUsername(coin.coinName)
                    .matchedGeometryEffect(id: "cn\(coin.coinName)", in: nameSpace)
                    .font(.headline)
                    .foregroundColor(.primary)
                highlightedUsername(coin.coinSymbol)
                    .matchedGeometryEffect(id: "cs\(coin.coinSymbol)", in: nameSpace)
                    .font(.subheadline)
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
        let highlighted = Text(String(username[range])).foregroundColor(.primaryTheme)
        let after = Text(String(username[range.upperBound...]))
        
        return before + highlighted + after
    }
    
}

#Preview {
    CoinHoldingListView(hasNavigate: true)
}

extension UserHolding {
    func valueString(using coinValues: [String: Double]) -> String {
        guard let value = coinValues[coin.coinSymbol] else { return "N/A" }
        return (quantity * value).formatted(.currency(code: "USD"))
    }
}
