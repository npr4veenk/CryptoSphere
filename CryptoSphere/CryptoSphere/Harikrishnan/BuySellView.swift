import SwiftUI
import Kingfisher
import AudioToolbox

struct BuySellView: View {
    
    let mot: String
    let coin: CoinDetails
    
    @State var marketPrice: Double = 0.0

    @FocusState private var isFocused: Bool
    
    @State private var selectedOption = "Buy in Units"
    let options = ["Buy in Units", "Buy in USD"]
    
    @State private var value: KeyPadValue = .init()
    
    @State private var isShowingAlert: Bool = true
    
    @Namespace private var nameSpace
    
    init(mot: String, coin: CoinDetails) {
        self.mot = mot
        self.coin = coin
        
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.font: UIFont(name: "ZohoPuvi-Semibold", size: 18) ?? UIFont.systemFont(ofSize: 18)],
            for: .normal
        )
        
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.orange
        UISegmentedControl.appearance().backgroundColor = UIColor.black
    }
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    SymbolWithNameView(coin: coin, searchText: "", nameSpace: nameSpace)
                    Spacer()
                    VStack(spacing: 4) {
                        Text("Market Price")
                            .font(.custom("ZohoPuvi-Medium", size: 16))
                            .foregroundStyle(Color.white.opacity(0.8))
                        
                        Text("\(marketPrice, format: .currency(code: "USD"))")
                            .font(.custom("ZohoPuvi-Semibold", size: 18))
                    }
                }
                .padding(.top, 35)
                
                Divider()
                    .frame(height: 1)
                    .background(Color.white)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                if mot == "Buy" {
                    Picker("Select Option", selection: $selectedOption) {
                        ForEach(options, id: \ .self) { option in
                            Text(option)
                                .font(.custom("ZohoPuvi-Bold", size: 18))
                        }
                    }
                    .scaleEffect(y: 1.1)
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.bottom, 30)
                }
                
                else if mot == "Sell"{
                    Text("Selling \(coin.coinSymbol) in Units")
                        .font(.custom("ZohoPuvi-Bold", size: 24))
                        .padding(.bottom, 30)
                }
                
                Button(action: {
                    actionHandler()
                }) {
                    Text(mot)
                        .font(.custom("ZohoPuvi-Bold", size: 27))
                        .frame(width: 200, height: 40)
                        .background(Color(.primaryTheme))
                        .cornerRadius(20)
                }
                .disabled(value.stringValue.isEmpty || Double(value.stringValue) == nil || Double(value.stringValue)! <= 0)
                
                Spacer()
                
                TextFieldInput(selectedOption: $selectedOption, coinImage: coin.imageUrl, value: $value, mot: mot)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .onAppear {
                Task{
                    await fetchPrice()
                }
            }
            
            if isShowingAlert {
                
                VStack(alignment: .leading) {
                    SymbolWithNameView(coin: coin, searchText: "", nameSpace: nameSpace)
                    
                    Text("Successfully Bought")
                        .font(.custom("ZohoPuvi-Bold", size: 22))
                        .foregroundColor(.white)
                    
                    HStack{
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.green)
                            .clipShape(Circle())  // Makes it circular
                            .scaleEffect(isShowingAlert ? 1.2 : 1.0) // Animates size
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isShowingAlert) // Pulsating effect
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.8))
                .cornerRadius(20)
                .shadow(radius: 10)
                .transition(.scale.combined(with: .opacity))
                .zIndex(10)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isShowingAlert = false
                            value = .init()
                        }
                    }
                }
            }
        }


    }
    
    func actionHandler() {
        guard !value.isEmpty else { return }
        
        let inputValue = value.stringValue
        if mot == "Buy" {
            if selectedOption == "Buy in Units" {
                print("Purchased \(inputValue) of \(coin.coinName)")
            } else {
                ServerResponce.shared.buySellCoin(buySell: mot.lowercased(), coinId: coin.id, quantity: ( Double(Int(inputValue) ?? 0) / marketPrice), completion: { _ in })
                print("Purchased \(Double(Int(inputValue) ?? 0)) of \(coin.coinName)")
                return
            }
        } else if mot == "Sell" {
            print("Sold \(inputValue)\(coin.id) of \(coin)")
        }
        withAnimation{
            isShowingAlert = true
        }
        
        ServerResponce.shared.buySellCoin(buySell: mot.lowercased(), coinId: coin.id, quantity: Double(Int(inputValue) ?? 0), completion: { _ in })
    }
    
    
    func fetchPrice() async {
        let price = try? await CryptoSphere.fetchPrice(coinName: coin.coinSymbol).result.list[0].lastPrice
        marketPrice = Double(price ?? "0")!
    }
}

#Preview {
    BuySellView(
        mot: "Buy",
        coin: CoinDetails(
            id: 325,
            coinName: "Bitcoin",
            coinSymbol: "BTCUSDT",
            imageUrl: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png"
        )
    )
}

#Preview {
    BuySellView(
        mot: "Sell",
        coin: CoinDetails(
            id: 325,
            coinName: "Bitcoin",
            coinSymbol: "BTCUSDT",
            imageUrl: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png"
        )
    )
}
