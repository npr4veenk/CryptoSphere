import Foundation

struct Cryptocurrency: Codable {
    let name: String
    let symbol: String
    let price: String
    let logo: String
    let change24hPercent: String
    let change24hValue: String
}

class GetCryptocurrency {
    static let shared = GetCryptocurrency()
    
    private var cache: [String: Cryptocurrency] = [:] // In-memory cache
    private let storageKey = "cachedCryptocurrencies"
    
    private init() {
        loadCacheFromStorage()
    }

    func getData(symbol: String) async -> Cryptocurrency {
        // Check memory cache for static details
        if let cachedCrypto = cache[symbol] {
            return await updateLivePrice(for: cachedCrypto)
        }
        
        // Try fetching static details from persistent storage
        if let storedCrypto = getStoredData(symbol: symbol) {
            return await updateLivePrice(for: storedCrypto)
        }

        // Fetch fresh static details from API
        do {
            let staticDetails = try await CoinDetailsResponse().fetchOneCoinDetails(symbol: symbol)
            
            // Save static details to cache and storage
            let cachedCrypto = Cryptocurrency(
                name: staticDetails.coinName,
                symbol: staticDetails.coinSymbol,
                price: "ERROR!", // Placeholder, will be updated
                logo: staticDetails.imageUrl,
                change24hPercent: "ERROR!", // Placeholder
                change24hValue: "ERROR!" // Placeholder
            )
            
            saveDataToCache(cachedCrypto)
            saveDataToStorage(cachedCrypto)
            
            return await updateLivePrice(for: cachedCrypto)
        } catch {
            print("Error fetching static data: \(error.localizedDescription)")
            return Cryptocurrency(name: "ERROR!", symbol: "ERROR!", price: "ERROR!", logo: "ERROR!", change24hPercent: "Error!", change24hValue: "Error!")
        }
    }

    private func updateLivePrice(for crypto: Cryptocurrency) async -> Cryptocurrency {
        do {
            let dynamicDetails = try await LivePriceResponse().fetchPrice(coinName: crypto.symbol).result.list.first { $0.symbol == crypto.symbol }
            
            guard let firstDynamicDetail = dynamicDetails else {
                throw CoinError.noData
            }

            return Cryptocurrency(
                name: crypto.name,
                symbol: crypto.symbol,
                price: firstDynamicDetail.lastPrice,
                logo: crypto.logo,
                change24hPercent: firstDynamicDetail.price24hPcnt,
                change24hValue: {
                    if let lastPrice = Double(firstDynamicDetail.lastPrice),
                       let prevPrice = Double(firstDynamicDetail.prevPrice24h) {
                        return String(format: "%.2f", lastPrice - prevPrice)
                    } else {
                        return "Error!"
                    }
                }()
            )
        } catch {
            print("Error fetching live price data: \(error.localizedDescription)")
            return crypto // Return the same object if live data fails
        }
    }

    
    // Save to in-memory cache
    private func saveDataToCache(_ crypto: Cryptocurrency) {
        cache[crypto.symbol] = crypto
    }
    
    // Save to UserDefaults
    private func saveDataToStorage(_ crypto: Cryptocurrency) {
        var storedCryptos = getAllStoredData()
        storedCryptos[crypto.symbol] = crypto
        
        if let encoded = try? JSONEncoder().encode(storedCryptos) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    // Fetch stored data
    private func getStoredData(symbol: String) -> Cryptocurrency? {
        return getAllStoredData()[symbol]
    }
    
    // Load all stored data
    private func getAllStoredData() -> [String: Cryptocurrency] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let storedCryptos = try? JSONDecoder().decode([String: Cryptocurrency].self, from: data) else {
            return [:]
        }
        return storedCryptos
    }
    
    // Load data from UserDefaults into cache on startup
    private func loadCacheFromStorage() {
        cache = getAllStoredData()
    }
}
