
import SwiftUI
import Combine

struct CoinsListView: View {
    @State var searchResults: [CoinDetails] = []
    @State var searchText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var searchTextSubject = PassthroughSubject<String, Never>()
    @State private var cancellables = Set<AnyCancellable>()
    
    @Environment(\.dismiss) var dismissE
    @Namespace var animation
    
    @State var page: Int = 1
    @State var isMorePage: Bool = true
    var dismiss: Bool
    @State private var selectedCoin: CoinDetails?

    var isMarket: Bool
    
    var body: some View {
        ZStack{
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.primaryTheme)
                        .font(.system(size: 20))
                    
                    TextField("Search...", text: $searchText)
                        .font(.custom("ZohoPuvi-Medium", size: 20))
                        .textInputAutocapitalization(.never)
                        .padding(.leading, 8)
                        .onChange(of: searchText) { _ ,newValue in
                            searchTextSubject.send(newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color("GrayButtonColor"))
                .cornerRadius(10)
                .onAppear {
                    Task {
                        await getCoins(with: "@All")
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                }
                
                if !searchResults.isEmpty {
                    ScrollView {
                        Text("")
                            .frame(height: 20)
                        
                        LazyVStack {
                            ForEach(searchResults, id: \.self) { coin in
                                VStack(alignment: .leading) {
                                    HStack{
                                        SymbolWithNameView(coin: coin, searchText: searchText, nameSpace: animation)
                                            .padding(.vertical)
                                            .padding(.trailing, 10)
                                        
                                        if isMarket{
                                            ChartViews(coin: coin.coinSymbol)
                                                .frame(width: 120, height: 80, alignment: .leading)
                                        }
                                        
                                        Spacer()
                                        
                                        
                                    }
                                    Divider()
                                    
                                }
                                .frame(maxWidth: .infinity)
                                .onTapGesture {
                                    if dismiss {
                                        dismissE()
                                    } else {
                                        withAnimation{
                                            selectedCoin = coin
                                        }
                                    }
                                }
                                .onAppear {
                                    Task {
                                        if isMorePage {
                                            if coin == searchResults[searchResults.count - 3] {
                                                try? await Task.sleep(nanoseconds: 1_000_000_00)
                                                if searchText != "" {
                                                    await getCoins(with: searchText)
                                                } else {
                                                    await getCoins(with: "@All")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                if isLoading {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
            .padding()
            .onAppear {
                setupSearchPublisher()
            }
            
            if let selectedCoin = selectedCoin, dismiss {
                NavigationStack{
                    ReceiveView(coin: selectedCoin, logoAnimation: animation)
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
    
    private func setupSearchPublisher() {
        searchTextSubject
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { newValue in
                Task {
                    isMorePage = true
                    searchResults = []
                    page = 1
                    if newValue == "" {
                        await self.getCoins(with: "@All")
                    } else {
                        await self.getCoins(with: newValue)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func getCoins(with text: String) async {
        
        isLoading = true
        errorMessage = nil
        do {
            if isMorePage {
                let newSearchResults = try await ServerResponce.shared.getCoins(searchText: text, page: page)
                searchResults.append(contentsOf: newSearchResults.coin)
                isMorePage = newSearchResults.total_pages > page
                page += 1
            }
            isLoading = false
        } catch {
            errorMessage = "\(error)"
        }
    }
    
}

#Preview {
    CoinsListView(dismiss: false, isMarket: true)
}


