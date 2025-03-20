import SwiftUI
import Kingfisher
import AudioToolbox

struct BuySellView: View {
    
    let mot: String
    var coinSymbol: String
    
    @State var coin: CoinDetails = CoinDetails(id: 0, coinName: "", coinSymbol: "", imageUrl: "")
    
    @State var marketPrice: Double = 0.0
    
    @State private var input = ""
    @FocusState private var isFocused: Bool
    
    @State private var selectedOption = "Buy in Units"
    let options = ["Buy in Units", "Buy in USD"]
    
    @State private var value: KeyPadValue = .init()
    
    init(mot: String, coinSymbol: String) {
        self.mot = mot
        self.coinSymbol = coinSymbol
        
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.font: UIFont(name: "ZohoPuvi-Semibold", size: 18) ?? UIFont.systemFont(ofSize: 18)],
            for: .normal
        )
        
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.orange
        UISegmentedControl.appearance().backgroundColor = UIColor.black
        
    }
    
    
    func getCoinDetails(completion: @escaping (CoinDetails?) -> Void) {
        guard let url = URL(string: "\(link)/coins/\(coinSymbol)") else { return completion(nil) }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            completion(data.flatMap { try? JSONDecoder().decode(CoinDetails.self, from: $0) })
        }.resume()
    }
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                      getCoinDetails { details in
                          DispatchQueue.main.async {
                              if let details = details {
                                  self.coin = details
                              }
                          }
                      }
                  }
            
            VStack {
                HStack {
                    KFImage(URL(string: coin.imageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(coin.coinName)
                            .font(.custom("ZohoPuvi-Semibold", size: 18))
                        
                        Text("\(coin.coinSymbol)")
                            .font(.custom("ZohoPuvi-Semibold", size: 16))
                            .foregroundStyle(Color.white.opacity(0.8))
                    }
                    
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
        
        ServerResponce.shared.buySellCoin(buySell: mot.lowercased(), coinId: coin.id, quantity: Double(Int(inputValue) ?? 0), completion: { _ in })
    }
    
    
    func fetchPrice() async {
        let price = try? await CryptoSphere.fetchPrice(coinName: coinSymbol).result.list[0].lastPrice
        marketPrice = Double(price ?? "0")!
    }
}

#Preview {
    BuySellView(
        mot: "Buy",
        coinSymbol: "BTCUSDT"
    )
}

#Preview {
    BuySellView(
        mot: "Sell",
        coinSymbol: "btcusdt"
    )
}

 


