import Foundation

struct CryptoResponse: Decodable {
    let result: CryptoMarket
}

struct CryptoMarket: Codable {
    let list: [CryptoTicker]
}

struct CryptoTicker: Codable {
    let symbol: String
    let lastPrice: String //CurrentPrice
    let prevPrice24h: String
    let price24hPcnt: String //Change
}


struct BybitPreviousDataResponse: Decodable {
    let retCode: Int
    let retMsg: String
    let result: PreviousResult
    let retExtInfo: [String: String]
    let time : Int
    
    struct PreviousResult: Codable {
        let list: [[String]]
    }
}

class LivePriceResponse{
    
    func fetchPrice(coinName: String) async throws -> CryptoResponse {
        let endpoint = "https://api.bybit.com/v5/market/tickers"
        
        guard var urlComponents = URLComponents(string: endpoint) else {
            print("[Error] Invalid URL components for endpoint: \(endpoint)")
            throw CoinError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "category", value: "spot"),
            URLQueryItem(name: "symbol", value: coinName.uppercased())
        ]
        
        guard let url = urlComponents.url else {
            print("[Error] Failed to construct final URL.")
            throw CoinError.invalidURL
        }
        
        print("[Debug] Final Request URL: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check if response is HTTPURLResponse
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[Error] Response is not a valid HTTPURLResponse.")
                throw CoinError.requestFailed
            }
            
            print("[Debug] HTTP Status Code: \(httpResponse.statusCode)")
            
            // Debugging: Print raw response data (limited to 500 chars)
            if let responseString = String(data: data, encoding: .utf8) {
                print("[Debug] Raw Response Data (truncated): \(responseString.prefix(500))")
            } else {
                print("[Debug] Unable to decode response data into a string.")
            }
            
            // Handle HTTP errors
            guard (200...299).contains(httpResponse.statusCode) else {
                print("[Error] Request failed with status code: \(httpResponse.statusCode)")
                
                let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
                print("[Error] Response Body: \(responseBody)")
                
                switch httpResponse.statusCode {
                case 400: throw CoinError.invalidSymbol
                case 429: throw CoinError.rateLimitExceeded
                default: throw CoinError.requestFailed
                }
            }
            
            // Decode JSON response
            do {
                let decodedResponse = try JSONDecoder().decode(CryptoResponse.self, from: data)
                print("[Success] Successfully decoded CryptoResponse.")
                return decodedResponse
            } catch {
                print("[Error] JSON Decoding Failed: \(error)")
                print("[Error] Raw JSON Data: \(String(data: data, encoding: .utf8) ?? "N/A")")
                throw error
            }
        } catch {
            print("[Error] Network request failed: \(error)")
            throw error
        }
    }

}
