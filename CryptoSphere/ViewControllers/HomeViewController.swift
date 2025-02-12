import UIKit

class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupActions()
    }
    
    let profileImageView: UIView = {
        let uiView = ProfileHeaderView(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        uiView.translatesAutoresizingMaskIntoConstraints = false
        uiView.configure(
            with: "Osama Bin Laden",
            imageURL: "https://assets.editorial.aetnd.com/uploads/2009/12/islamic-extremist-osama-bin-laden.jpg"
        )
        return uiView
    }()
    
    let portfolioView: UIView = {
        let uiView = PortfolioView()
        uiView.translatesAutoresizingMaskIntoConstraints = false
        uiView.configure(balance: "$5,271.39", profit: "+$2,979.23", percentage: "(130.62%)", profitColor: .green)
        return uiView
    }()
    
    let myFundslabel: UILabel = {
       let label = UILabel()
        label.text = "My Funds"
        label.font = UIFont.systemFont(ofSize: 20, weight: .black)
        label.textColor = .font
        label.layer.opacity = 0.7
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let viewAllButton: UIButton = {
        let button = UIButton()
        button.setTitle("View All", for: .normal)
        button.backgroundColor = .clear
        return button
    }()
    
    let myFundsCollectionView: UICollectionView = {
        let collectionView = FundsCollectionView()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        
        let cryptos = [
            Cryptocurrency(
                name: "Bitcoin",
                symbol: "BTCUSDT",
                price: "$43,567.89",
                change: "+5.67%",
                logo: "https://cryptologos.cc/logos/bitcoin-btc-logo.png"
            ),
            Cryptocurrency(
                name: "Ethereum",
                symbol: "ETHUSDT",
                price: "$2,345.67",
                change: "-2.34%",
                logo: "https://cryptologos.cc/logos/ethereum-eth-logo.png"
            ),
            Cryptocurrency(
                name: "Solana",
                symbol: "SOLUSDT",
                price: "$98.76",
                change: "+10.23%",
                logo: "https://cryptologos.cc/logos/solana-sol-logo.png"
            ),
            Cryptocurrency(
                name: "Cardano",
                symbol: "ADAUSDT",
                price: "$1.23",
                change: "+3.45%",
                logo: "https://cryptologos.cc/logos/cardano-ada-logo.png"
            ),
            Cryptocurrency(
                name: "Polkadot",
                symbol: "DOTUSDT",
                price: "$18.92",
                change: "-1.23%",
                logo: "https://cryptologos.cc/logos/polkadot-new-dot-logo.png"
            ),
            Cryptocurrency(
                name: "Ripple",
                symbol: "XRPUSDT",
                price: "$0.89",
                change: "+7.82%",
                logo: "https://cryptologos.cc/logos/xrp-xrp-logo.png"
            ),
            Cryptocurrency(
                name: "Avalanche",
                symbol: "AVAXUSDT",
                price: "$76.54",
                change: "+4.56%",
                logo: "https://cryptologos.cc/logos/avalanche-avax-logo.png"
            ),
            Cryptocurrency(
                name: "Chainlink",
                symbol: "LINKUSDT",
                price: "$15.67",
                change: "-0.89%",
                logo: "https://cryptologos.cc/logos/chainlink-link-logo.png"
            ),
            Cryptocurrency(
                name: "Polygon",
                symbol: "MATICUSDT",
                price: "$1.45",
                change: "+6.78%",
                logo: "https://cryptologos.cc/logos/polygon-matic-logo.png"
            ),
            Cryptocurrency(
                name: "Cosmos",
                symbol: "ATOMUSDT",
                price: "$21.34",
                change: "-3.21%",
                logo: "https://cryptologos.cc/logos/cosmos-atom-logo.png"
            )
        ]
        
        collectionView.configure(with: cryptos)
        return collectionView
    }()
    
    func setupViews(){
        view.addSubview(profileImageView)
        view.addSubview(portfolioView)
        view.addSubview(myFundsCollectionView)
        view.addSubview(myFundslabel)
        view.addSubview(viewAllButton)
        
        let searchIcon = UIImage(systemName: "magnifyingglass")?.withConfiguration(
            UIImage.SymbolConfiguration(weight: .bold)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: searchIcon, style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem?.tintColor = .font
        
        func setGradientBackground(view: UIView) {
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = view.bounds
            gradientLayer.colors = [UIColor.greyButtonDarkMode.cgColor, UIColor.black.cgColor]
            gradientLayer.locations = [0.0, 0.2] // Gray at 0%, fully black after 20%
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)  // Starts from top-center
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)    // Ends at bottom-center
            view.layer.insertSublayer(gradientLayer, at: 0)
        }
        
        setGradientBackground(view: view)
    }
    
    func setupActions(){
        if let profileHeaderView = profileImageView as? ProfileHeaderView {
            profileHeaderView.tapAction = { [weak self] in
                self?.profileTapped()
            }
        }
    }
    func setupConstraints(){
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -35),
            
            portfolioView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            portfolioView.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 28),
            portfolioView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.95),
            
            myFundslabel.topAnchor.constraint(equalTo: portfolioView.bottomAnchor, constant: 16),
            myFundslabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            
            myFundsCollectionView.topAnchor.constraint(equalTo: myFundslabel.bottomAnchor, constant: 0),
            myFundsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            myFundsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            myFundsCollectionView.heightAnchor.constraint(equalToConstant: 220)
        ])
    }
    
    
    
    
    
    
    
    
    
    @objc func profileTapped() {
        let actionSheetVC = UIViewController()
        actionSheetVC.modalPresentationStyle = .automatic
        actionSheetVC.view.backgroundColor = .background
        actionSheetVC.sheetPresentationController?.prefersGrabberVisible = true
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        actionSheetVC.view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.centerXAnchor.constraint(equalTo: actionSheetVC.view.centerXAnchor),
            closeButton.centerYAnchor.constraint(equalTo: actionSheetVC.view.centerYAnchor)
        ])
        
        present(actionSheetVC, animated: true)
    }
}

#Preview {
    HomeViewController()
}
