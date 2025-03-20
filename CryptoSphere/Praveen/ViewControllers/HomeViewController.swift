import UIKit
import SwiftUI

class HomeViewController: UIViewController, UICollectionViewDelegate {
    
    
    // MARK: - Properties
    private let getCryptocurrency = GetCryptocurrency.shared
    private let userSession = UserSession.shared
    private var refreshTimer: Timer?
    
    // MARK: - UI Elements
    private let profileImageView: ProfileHeaderView = {
        let view = ProfileHeaderView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let chatButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        button.tintColor = .font
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30) // Remove y-offset since UIBarButtonItem manages layout
        return button
    }()
    
    private let portfolioView: PortfolioView = {
        let view = PortfolioView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let myFundsLabel: UILabel = {
        let label = UILabel()
        label.text = "My Funds"
        label.font = Fonts.getPuviFont("regular", 16)
        label.textColor = .font
        label.layer.opacity = 0.8
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let viewAllButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View All", for: .normal)
        button.titleLabel?.font = Fonts.getPuviFont("medium", 16)
        button.tintColor = .secondaryFont
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var fundsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [myFundsLabel, viewAllButton])
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let addFundsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .secondaryFont
        button.backgroundColor = .grayButton
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let myFundsCollectionView: FundsCollectionView = {
        let collectionView = FundsCollectionView()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    private lazy var cryptoTableLikeView: CryptoTableLikeView = {
        let view = CryptoTableLikeView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
//    private let loadingView = CustomLoadingView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupActions()
        //        startRefreshingData()
        loadCryptoData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
//     MARK: - Data Loading
        private func startRefreshingData() {
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
                self?.loadCryptoData()
            }
            refreshTimer?.fire()
        }
    
    private func loadCryptoData() {
        
        let serverResponse = ServerResponce.shared
        
        Task{
            profileImageView.configure(with: UserSession.shared?.userName! ?? "Osama Bin Laden", imageURL: UserSession.shared?.profileImageURL ?? "https://assets.editorial.aetnd.com/uploads/2009/12/islamic-extremist-osama-bin-laden.jpg")
        }
        
        Task {
            var balance = try await serverResponse.calculateBalance()
            print("Balance: \(String(balance))")
//            balance = 420000

            portfolioView.configure(balance: String(balance), profit: "", percentage: "", profitColor: .green, receiveAction: { [weak self] in
            self?.receiveButtonTapped()
       }, sendAction: { [weak self] in
           self?.sendButtonTapped()
       })
   }
        
        Task {
            let mostPopular = await fetchCryptos(symbols: ["BTCUSDT", "ETHUSDT", "BNBUSDT", "SOLUSDT"]) // Top market cap coins
            let trending = await fetchCryptos(symbols: ["DOGEUSDT", "SHIBUSDT", "DAIUSDT", "LTCUSDT"]) // Most hyped/meme coins
            let recommended = await fetchCryptos(symbols: ["AVAXUSDT", "LINKUSDT", "ATOMUSDT", "INJUSDT"]) // Strong fundamental projects
            
            await MainActor.run {
                cryptoTableLikeView.configure(mostPopular: mostPopular, trending: trending, recommended: recommended)
            }
        }
        
        Task{
            let coins = try await serverResponse.fetchUserHoldings().map { $0.coin }.compactMap(\.coinSymbol)
            var myFunds: [Cryptocurrency] = []
            
            print("COINS.COUNT : \(coins.count)")

            if coins.count == 0 {
                myFunds = await fetchCryptos(symbols:["BTCUSDT", "ETHUSDT", "SOLUSDT", "ADAUSDT", "DOTUSDT", "XRPUSDT"])
            }else{
                myFunds = await fetchCryptos(symbols:coins)
            }
            
            await MainActor.run {
                myFundsCollectionView.configure(with: myFunds)
            }
        }
    }
    
    
    private func fetchCryptos(symbols: [String]) async -> [Cryptocurrency] {
        await withTaskGroup(of: (Int, Cryptocurrency).self) { group in
            for (index, symbol) in symbols.enumerated() {
                group.addTask {
                    let crypto = await self.getCryptocurrency.getData(symbol: symbol)
                    return (index, crypto)
                }
            }
            
            var results: [(Int, Cryptocurrency)] = []
            for await result in group {
                results.append(result)
            }
            
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    
    // MARK: - Setup Views
    private func setupViews() {
        view.addSubview(profileImageView)
        view.addSubview(chatButton)
        view.addSubview(portfolioView)
        view.addSubview(fundsStackView)
        view.addSubview(addFundsButton)
        view.addSubview(myFundsCollectionView)
        view.addSubview(cryptoTableLikeView)
        
        myFundsCollectionView.fundsDelegate = self
        cryptoTableLikeView.delegate = self
        
//        view.addSubview(loadingView) // Add loading view
//        view.bringSubviewToFront(loadingView) // Ensure it appears on top\
        
        HomeViewController.setGradientBackground(view: view)
        view.bringSubviewToFront(addFundsButton)
    }
    
    
    
    // MARK: - Setup Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Profile Image View
            profileImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            
            chatButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            chatButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor, constant: 0),
            
            // Portfolio View
            portfolioView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            portfolioView.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
//            portfolioView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.95),
            portfolioView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            portfolioView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            // Funds Stack View
            fundsStackView.topAnchor.constraint(equalTo: portfolioView.bottomAnchor, constant: 14),
            fundsStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            fundsStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            // My Funds Collection View
            myFundsCollectionView.topAnchor.constraint(equalTo: fundsStackView.bottomAnchor, constant: 6),
            myFundsCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            myFundsCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            myFundsCollectionView.heightAnchor.constraint(equalToConstant: 180),
            
            // Add Funds Button
            addFundsButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            addFundsButton.topAnchor.constraint(equalTo: fundsStackView.bottomAnchor, constant: 8),
            addFundsButton.widthAnchor.constraint(equalToConstant: 44),
            addFundsButton.heightAnchor.constraint(equalToConstant: 180),
            
            
            // Crypto Table Like View
            cryptoTableLikeView.topAnchor.constraint(equalTo: myFundsCollectionView.bottomAnchor, constant: 0),
            cryptoTableLikeView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            cryptoTableLikeView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            cryptoTableLikeView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
//            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
//            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Setup Actions
    private func setupActions() {
        // Profile and chat actions
        profileImageView.tapAction = { [weak self] in
            self?.profileButtonClicked()
        }
        chatButton.addTarget(self, action: #selector(chatButtonClicked), for: .touchUpInside)
        
        // Fund-related buttons
        viewAllButton.addTarget(self, action: #selector(viewAllButtonClicked), for: .touchUpInside)
        addFundsButton.addTarget(self, action: #selector(addFundsButtonClicked), for: .touchUpInside)
    }
    
    
    // MARK: - Gradient Background
    static func setGradientBackground(view: UIView) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [UIColor.grayButton.cgColor, UIColor.background.cgColor]
        gradientLayer.locations = [0.0, 0.3] // Gray at 0%, fully black after 20%
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)  // Starts from top-center
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)    // Ends at bottom-center
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    
    
    // MARK: - Navigation Methods
    private func navigateToProfile() {
        present(UIViewController(), animated: true)
    }
    
    private func navigateToChats() {
        navigationController?.pushViewController(UIHostingController(rootView: ChatListView()), animated: true)
        navigationController?.navigationBar.isHidden = false
    }
    
    private func navigateToMarkets() {
        if let tabBarController = self.tabBarController {
            tabBarController.selectedIndex = 1 // Markets tab
        }
    }
    
    private func navigateToTradeTab() {
        if let tabBarController = self.tabBarController {
            tabBarController.selectedIndex = 2 // Trade tab
        }
    }
    
    private func navigateToWalletTab() {
        if let tabBarController = self.tabBarController {
            tabBarController.selectedIndex = 3 // Wallet tab
        }
    }
    
    private func navigateToTradeScreen(with symbol: String) {
        if let tabBarController = tabBarController {
            tabBarController.selectedIndex = 2 // Trade tab
            
            if let navController = tabBarController.viewControllers?[2] as? UINavigationController,
               let tradeVC = navController.topViewController as? TradeViewController {
                Task {
                    await tradeVC.configure(symbol: symbol)
                }
            }
        }
    }
    
    private func navigateToReceiveCoins() {
        let hostingController = UIHostingController(rootView: CoinsListView(dismiss: false, isMarket: false))
        hostingController.sheetPresentationController?.prefersGrabberVisible = true
        navigationController?.present(hostingController, animated: true)
    }
    
    private func navigateToSendCoins() {
        let hostingController = UIHostingController(rootView: CoinHoldingListView(hasNavigate: true))
        hostingController.sheetPresentationController?.prefersGrabberVisible = true
        navigationController?.present(hostingController, animated: true)
    }
    
    // MARK: - Button Actions
    @objc private func profileButtonClicked() {
        navigateToProfile()
    }
    
    @objc private func chatButtonClicked() {
        navigateToChats()
    }
    
    @objc private func viewAllButtonClicked() {
        navigateToWalletTab()
    }
    
    @objc private func addFundsButtonClicked() {
        navigateToMarkets()
    }
    
    func receiveButtonTapped() {
        navigateToReceiveCoins()
    }
    
    func sendButtonTapped() {
        navigateToSendCoins()
    }
}

// MARK: - FundsCollectionViewDelegate
extension HomeViewController: FundsCollectionViewDelegate {
    func fundsCollectionView(didSelectCryptoWithSymbol symbol: String) {
        navigateToTradeScreen(with: symbol)
    }
    
    func didScrollCollectionView(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        UIView.animate(withDuration: 0.2) {
            if offsetX == 0 {
                self.addFundsButton.transform = .identity // Show at original position
                self.addFundsButton.alpha = 1
            } else {
                self.addFundsButton.transform = CGAffineTransform(translationX: -600, y: 0) // Slide left
                self.addFundsButton.alpha = 0
            }
        }
    }
}

// MARK: - CryptoTableLikeViewDelegate
extension HomeViewController: CryptoTableLikeViewDelegate {
    func didSelectCrypto(symbol: String) {
        navigateToTradeScreen(with: symbol)
    }
}

#Preview {
    HomeViewController()
}
