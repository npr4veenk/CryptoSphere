import Foundation

struct MarketData: Decodable {
    let id: String
    let symbol: String
    let name: String
    let marketData: ActualMarketData

    enum CodingKeys: String, CodingKey {
        case id, symbol, name
        case marketData = "market_data"
    }
}

struct ActualMarketData: Decodable {
    let marketCap: [String: Double]
    let totalVolume: [String: Double]
    let circulatingSupply: Double
    let totalSupply: Double?
    let ath: [String: Double]?
    let atl: [String: Double]?

    enum CodingKeys: String, CodingKey {
        case marketCap = "market_cap"
        case totalVolume = "total_volume"
        case circulatingSupply = "circulating_supply"
        case totalSupply = "total_supply"
        case ath = "ath"
        case atl = "atl"
    }
}

class MarketDataResponse {
    func fetchCryptoData(for id: String) async -> ActualMarketData? {
        let urlString = "https://api.coingecko.com/api/v3/coins/\(id)?localization=false"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Debugging: Print raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON Response:\n\(jsonString)")
            }
            
            let crypto = try JSONDecoder().decode(MarketData.self, from: data)
            return crypto.marketData
        } catch {
            print("Error fetching data: \(error.localizedDescription)")
            return nil
        }
    }
}
