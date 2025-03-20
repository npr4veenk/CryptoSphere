import UIKit
import SwiftUI

class TradeViewController: UIViewController {
    
    struct CryptoData: Equatable {
        let symbol: String
        let currentPrice: String
        let priceChange24h: Double
        let percentageChange24h: Double
        let chartData: [PreviousData]
        
        let marketCap: String
        let totalVolume: String
        let circulatingSupply: String
        let totalSupply: String
        let allTimeHigh: String
        let allTimeLow: String
        
        var formattedPercentage: String {
            return String(format: "%+.2f%%", percentageChange24h)
        }
        
        var formattedPriceChange: String {
            return String(format: "%+.2f (%@)", priceChange24h, formattedPercentage)
        }
        
        static let mock = CryptoData(
            symbol: "BTCUSDT",
            currentPrice: "85753.04",
            priceChange24h: 0.34,
            percentageChange24h: 2.32,
            chartData: [],
            marketCap: "450,000,000,000",
            totalVolume: "32,000,000,000",
            circulatingSupply: "19,500,000",
            totalSupply: "21,000,000",
            allTimeHigh: "$69,000.00",
            allTimeLow: "$67.81"
        )
    }
    
    
    private let coinDetailsResponse = CoinDetailsResponse()
    
    private var cryptoData: CryptoData?
    private var updateTimer: Timer?
    var symbol: String?
    private var chartData: [PreviousData] = []
    private var currentInterval: String = "1"
    
    private let loadingView = CustomLoadingView()
    
    // MARK: - UI Components
    private var tradeTitleView: UILabel = {
        let label = UILabel()
        label.textColor = .font
        label.font = Fonts.getPuviFont("Medium", 20)
//        label.text = "TRADE"
        label.textAlignment = .center
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .background
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .background
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let symbolLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .label
//        label.backgroundColor = .grayButton
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true // Enable interaction
        return label
    }()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .font
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let changeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let chartView: GradientChartView = {
        let configuration = GradientChartView.Configuration.default
        let view = GradientChartView(configuration: configuration)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let timeSegmentControl: UISegmentedControl = {
        let items = ["1D", "5D", "1M", "6M", "1Y", "All"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = .primaryTheme
        control.setTitleTextAttributes(
            [.foregroundColor: UIColor.font], for: .normal)
        control.setTitleTextAttributes(
            [.foregroundColor: UIColor.font], for: .selected)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let dataStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let floatingButtonsContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        HomeViewController.setGradientBackground(view: view)
        
        
        // Create a gradient layer for the background
        //        let gradientLayer = CAGradientLayer()
        //        gradientLayer.frame = view.bounds
        //        gradientLayer.colors = [
        //            UIColor.black.withAlphaComponent(0).cgColor, // Top (transparent black)
        //            UIColor.black.withAlphaComponent(0.8).cgColor, // Center (darkest)
        //            UIColor.black.withAlphaComponent(0).cgColor  // Bottom (transparent black)
        //        ]
        //        gradientLayer.locations = [0.0, 0.5, 0.0] // Middle is darkest
        //
        //        // Add gradient to the view's layer
        //        view.layer.insertSublayer(gradientLayer, at: 0)
        //
        //        // Optional: Add blur effect if desired (as per your original code)
        //        let blurEffect = UIBlurEffect(style: .dark)
        //        let blurView = UIVisualEffectView(effect: blurEffect)
        //        blurView.layer.opacity = 0.3
        //        blurView.translatesAutoresizingMaskIntoConstraints = false
        //        view.addSubview(blurView)
        //
        //        // Constraints for the blur effect view
        //        NSLayoutConstraint.activate([
        //            blurView.topAnchor.constraint(equalTo: view.topAnchor),
        //            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        //            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        //            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        //        ])
        
        return view
    }()
    
    
    private let buyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Buy", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .primaryTheme
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let sellButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sell", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .grayButton
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let emptyView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Initialization
    init(symbol: String? = "BTCUSDT") {
        self.symbol = symbol
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.symbol = "BTCUSDT"
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        Task{
            await startDataUpdates()
        }
        if let symbol = symbol {
            Task{
                await configure(symbol: symbol)
            }
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .background
        
        navigationItem.titleView = tradeTitleView
        navigationItem.titleView?.frame = CGRect(x: 0, y: 0, width: 100, height: 44)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(symbolLabel)
        contentView.addSubview(logoImageView)
        contentView.addSubview(priceLabel)
        contentView.addSubview(changeLabel)
        contentView.addSubview(chartView)
        contentView.addSubview(timeSegmentControl)
        contentView.addSubview(dataStackView)
        contentView.addSubview(emptyView)
        
        view.addSubview(floatingButtonsContainer)
        floatingButtonsContainer.addSubview(buyButton)
        floatingButtonsContainer.addSubview(sellButton)
        
        // Add loading view to the main view
        view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        
        setupConstraints()
        setupActions()
        
        updateUI(with: CryptoData.mock)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            symbolLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            symbolLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            logoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            logoImageView.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor, constant: -2),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            
            priceLabel.topAnchor.constraint(equalTo: symbolLabel.bottomAnchor, constant: 8),
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            changeLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 4),
            changeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            chartView.topAnchor.constraint(equalTo: changeLabel.bottomAnchor, constant: 8),
            chartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            chartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            chartView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height * 0.35),
            
            timeSegmentControl.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 0),
            timeSegmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeSegmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeSegmentControl.heightAnchor.constraint(equalToConstant: 35),
            
            dataStackView.topAnchor.constraint(equalTo: timeSegmentControl.bottomAnchor, constant: 24),
            dataStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dataStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dataStackView.bottomAnchor.constraint(equalTo: emptyView.topAnchor, constant: 0),
            
            floatingButtonsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            floatingButtonsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            floatingButtonsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            floatingButtonsContainer.heightAnchor.constraint(equalToConstant: 80),
            
            sellButton.leadingAnchor.constraint(equalTo: floatingButtonsContainer.leadingAnchor, constant: 16),
            sellButton.bottomAnchor.constraint(equalTo: floatingButtonsContainer.bottomAnchor, constant: -16),
            sellButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width/2.25),
            sellButton.heightAnchor.constraint(equalToConstant: 50),
            
            buyButton.trailingAnchor.constraint(equalTo: floatingButtonsContainer.trailingAnchor, constant: -16),
            buyButton.bottomAnchor.constraint(equalTo: floatingButtonsContainer.bottomAnchor, constant: -16),
            buyButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width/2.25),
            buyButton.heightAnchor.constraint(equalTo: sellButton.heightAnchor, multiplier: 1),
            
            emptyView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            emptyView.heightAnchor.constraint(equalToConstant: 80),

            // Constraints for loading view
//            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        timeSegmentControl.addTarget(
            self, action: #selector(timeIntervalChanged), for: .valueChanged)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(symbolLabelTapped))
        symbolLabel.addGestureRecognizer(tapGesture)
        
        sellButton.addTarget(self, action: #selector(sellButtonClicked), for: .touchUpInside)
        buyButton.addTarget(self, action: #selector(buyButtonClicked), for: .touchUpInside)
    }
    
    // MARK: - Navigation Methods
    private func navigateToBuyView(coinSymbol: String) {
        let buySellViewHostingController = UIHostingController(rootView: BuySellView(
            mot: "Buy",
            coinSymbol: coinSymbol
        ))
        navigationController?.pushViewController(buySellViewHostingController, animated: true)
    }

    private func navigateToSellView(coinSymbol: String) {
        let buySellViewHostingController = UIHostingController(rootView: BuySellView(
            mot: "Sell",
            coinSymbol: coinSymbol
        ))
        navigationController?.pushViewController(buySellViewHostingController, animated: true)
    }

    private func navigateToCoinSelector() {
        let coinsListView = CoinsListView(dismiss: true, isMarket: true){ coin in
            Task{
                await self.configure(symbol: coin.coinSymbol)
            }
        }
        let hostingController = UIHostingController(rootView: coinsListView)
        self.navigationController?.present(hostingController, animated: true)
    }

    // MARK: - Button Actions
    @objc private func sellButtonClicked() {
        navigateToSellView(coinSymbol: symbol ?? "")
    }

    @objc private func buyButtonClicked() {
        navigateToBuyView(coinSymbol: symbol ?? "")
    }

    @objc private func symbolLabelTapped() {
        navigateToCoinSelector()
    }
    
    func configure(symbol: String) async {
        self.symbol = symbol
        tradeTitleView.text = symbol.uppercased()
        symbolLabel.text = symbol.uppercased() + " ▼"
        await startDataUpdates()
        
        Task{
            let coinInfo = try await coinDetailsResponse.fetchOneCoinDetails(symbol: symbol)
            if let url = URL(string: coinInfo.imageUrl){
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.logoImageView.image = image
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Data Management
    private func startDataUpdates() async {
        // Initial updates
        
        loadingView.show()
        await updatePriceData()
        await updateChartData()
        loadingView.hide()
        
        // Setup timer for periodic updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true)
        { [weak self] _ in
            Task {
                await self?.updatePriceData()
            }
        }
    }
    
    private func updatePriceData() async {
        // Ensure the symbol is valid
        guard let symbol = symbol, !symbol.isEmpty else {
            print("Symbol is nil or empty")
            return
        }

        do {
            // Fetch coin details
            let coinInfo = try await CoinDetailsResponse().fetchOneCoinDetails(symbol: symbol)
            
            // Fetch live price
            do {
                async let priceResponse = LivePriceResponse().fetchPrice(coinName: symbol)
                let priceResult = try await priceResponse
                guard let ticker = priceResult.result.list.first else {
                    print("No ticker found in price result")
                    return
                }

                // Fetch market data
                do {
                    async let marketDataResponse = MarketDataResponse().fetchCryptoData(for: coinInfo.coinName.lowercased())
                    guard let marketData = await marketDataResponse else {
                        print("Market data is nil")
                        return
                    }

                    // Prepare data for UI update
                    let data = CryptoData(
                        symbol: ticker.symbol,
                        currentPrice: ticker.lastPrice,
                        priceChange24h: (Double(ticker.lastPrice) ?? 0) - (Double(ticker.prevPrice24h) ?? 0),
                        percentageChange24h: Double(ticker.price24hPcnt) ?? 0,
                        chartData: chartData,
                        marketCap: marketData.marketCap["usd"]?.formattedString() ?? "N/A",
                        totalVolume: marketData.totalVolume["usd"]?.formattedString() ?? "N/A",
                        circulatingSupply: marketData.circulatingSupply.formattedString(),
                        totalSupply: marketData.totalSupply?.formattedString() ?? "N/A",
                        allTimeHigh: marketData.ath?["usd"]?.formattedString() ?? "N/A",
                        allTimeLow: marketData.atl?["usd"]?.formattedString() ?? "N/A"
                    )

                    // Update UI on the main thread
                    await MainActor.run {
                        updateUI(with: data)
                    }
                } catch {
                    print("Error fetching market data: \(error)")
                }
            } catch {
                print("Error fetching price data: \(error)")
            }
        } catch {
            print("Error fetching coin details: \(error)")
        }
    }

    private func updateUI(with data: CryptoData) {
        // Always update the UI, regardless of whether the data has changed
        cryptoData = data
        
        symbolLabel.text = "\(data.symbol) ▼"
        priceLabel.text = "$\(data.currentPrice)"
        
        updateDataItems(with: data)
        
        if !data.chartData.isEmpty {
            chartData = data.chartData
            updateChart()
        }
    }
    
    private func updateChartData() async {
        func getTimestamp(forDaysAgo days: Int) -> Int {
            return Int(
                Calendar.current.date(byAdding: .day, value: -days, to: Date())!
                    .timeIntervalSince1970 * 1000)
        }
        
        func getData(type: Calendar.Component, diff: Int) async -> [PreviousData] {
            let now = Int(Date().timeIntervalSince1970 * 1000)
            let intervals = [1, 3, 5, 30, 60, 120, 240, 360, 720]
            let start: Int
            let interval: String
            
            if diff == 100 {
                start = await Int(coinDetailsResponse.getGenesisDate(for: symbol ?? "") ?? 10)
                interval = "D"
            } else {
                start = Int(Calendar.current.date(byAdding: type, value: -diff, to: Date())!
                    .timeIntervalSince1970 * 1000)
                interval = String(
                    intervals.first {
                        $0 >= Int((Double(now - start) / (1000 * 60 * 300)).rounded(.up))
                    } ?? intervals.last!)
            }
            
            do {
                let previousPriceResponse = PreviousPriceResponse()
                let livePriceResponse = LivePriceResponse()
                
                var chartData = try await previousPriceResponse.fetchPreviousPrice(
                    coinName: symbol ?? "", from: start, to: now, interval: interval)
                let lastprice = try await livePriceResponse.fetchPrice(coinName: symbol ?? "").result.list[0].lastPrice
                
                chartData = chartData.reversed()
                
                chartData.append(
                    PreviousData(
                        time: now, open: 0, high: 0, low: 0,
                        close: Double(lastprice) ?? 0))
                
                return chartData
            } catch {
                print("Error fetching data: \(error)")
            }
            return []
        }
        
        switch currentInterval {
        case "1D":
            chartData = await getData(type: .day, diff: 1)
        case "5D":
            chartData = await getData(type: .day, diff: 5)
        case "1M":
            chartData = await getData(type: .month, diff: 1)
        case "6M":
            chartData = await getData(type: .month, diff: 6)
        case "1Y":
            chartData = await getData(type: .year, diff: 1)
        case "All":
            chartData = await getData(type: .year, diff: 100)
        default:
            chartData = await getData(type: .day, diff: 1)
        }
        
        await MainActor.run {
            updateChart()
        }
    }
    
    private func updateChart() {
        guard !chartData.isEmpty else { return }
        
        let closePrices = chartData.map { CGFloat($0.close) }
        let minPrice = closePrices.min() ?? 0
        let maxPrice = closePrices.max() ?? 0
        
        // Calculate the price change for the selected period
        let firstPrice = closePrices.first ?? 0
        let lastPrice = closePrices.last ?? 0
        
        // Calculate absolute and percentage changes
        let priceChange = lastPrice - firstPrice
        let percentageChange = ((lastPrice - firstPrice) / firstPrice) * 100
        
        // Update change label with the period-specific change
        let formattedChange = String(format: "%+.2f (%+.2f%%)",
                                     Double(priceChange),
                                     Double(percentageChange))
        
        changeLabel.text = formattedChange
        
        // Update color based on the period change
        let priceChangeColor = lastPrice >= firstPrice ?
        UIColor(red: 0, green: 0.8, blue: 0, alpha: 1.0) : // Green for increase
        UIColor(red: 0.8, green: 0, blue: 0, alpha: 1.0)   // Red for decrease
        
        changeLabel.textColor = priceChangeColor
        
        // Update the chart configuration with the new color
        let chartConfig = GradientChartView.Configuration(
            dataPoints: closePrices,
            timeLabels: ["1D", "5D", "1M", "6M", "1Y", "All"],
            lineColor: priceChangeColor,
            gridColor: UIColor.gray.withAlphaComponent(0.1),
            textColor: .font,
            minValue: minPrice * 0.992,
            maxValue: maxPrice * 1.006,
            isGradientEnabled: true,
            showGridLines: false,
            lineWidth: 2.0,
            fontSize: 12.0
        )
        
        // Animate the chart update
        UIView.transition(
            with: chartView,
            duration: 0.4,
            options: [.beginFromCurrentState, .transitionCrossDissolve, .curveEaseOut, .allowAnimatedContent],
            animations: {
                self.chartView.configure(with: chartConfig)
            },
            completion: nil
        )
    }
    
    private func updateDataItems(with data: CryptoData) {
        dataStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let dataItems = [
            ("Market cap", data.marketCap),
            ("Total volume", data.totalVolume),
            ("Circulating supply", data.circulatingSupply),
            ("Total supply", data.totalSupply),
            ("All time high", data.allTimeHigh),
            ("All time low", data.allTimeLow),
        ]
        
        dataItems.forEach { title, value in
            let itemView = createDataItemView(title: title, value: value)
            dataStackView.addArrangedSubview(itemView)
        }
    }
    
    private func createDataItemView(title: String, value: String) -> UIView {
        let container = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .secondaryFont
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16)
        valueLabel.textColor = .font
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 35),
        ])
        
        return container
    }
    
    // MARK: - Actions
    @objc private func timeIntervalChanged(_ sender: UISegmentedControl) {
        let intervals = ["1D", "5D", "1M", "6M", "1Y", "All"]
        currentInterval = intervals[sender.selectedSegmentIndex]
        Task {
            await updateChartData()
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}

extension Double {
    func formattedString() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2 // Adjust precision if needed
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}


#Preview {
    TradeViewController(symbol: "BTCUSDT")
}
