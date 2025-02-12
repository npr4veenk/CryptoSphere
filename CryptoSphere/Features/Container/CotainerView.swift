import UIKit
import SwiftUI

struct Cryptocurrency: Codable {
    let name: String
    let symbol: String
    let price: String
    let change: String
    let logo: String
}

class FundsCollectionView: UICollectionView {
    private var cryptos: [Cryptocurrency] = []
    
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 185, height: 180)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.scrollDirection = .horizontal
        
        super.init(frame: .zero, collectionViewLayout: layout)
        
        backgroundColor = .clear
        delegate = self
        dataSource = self
        register(FundsCollectionViewCell.self, forCellWithReuseIdentifier: "CryptoCell")
        showsHorizontalScrollIndicator = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with cryptos: [Cryptocurrency]) {
        self.cryptos = cryptos
        reloadData()
    }
}

extension FundsCollectionView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cryptos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CryptoCell", for: indexPath) as! FundsCollectionViewCell
        let crypto = cryptos[indexPath.item]
        cell.configure(with: crypto)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected item: \(cryptos[indexPath.item].name)")
    }
}

class FundsCollectionViewCell: UICollectionViewCell {
    let logoImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    let config = UIImage.SymbolConfiguration(pointSize: 45, weight: .regular)

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textColor = .font
        return label
    }()
    
    let symbolLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .font
        return label
    }()
    
    let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .font
        return label
    }()
    
    let changeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .font
        return label
    }()

    var chartHostingController: UIHostingController<ChartViews>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        backgroundColor = .greyBackgroundDarkMode
        layer.cornerRadius = 30
        
        addSubview(logoImageView)
        addSubview(nameLabel)
        addSubview(symbolLabel)
        addSubview(priceLabel)
        addSubview(changeLabel)

        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        symbolLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        changeLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            logoImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            logoImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            logoImageView.widthAnchor.constraint(equalToConstant: 40),
            logoImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.centerYAnchor.constraint(equalTo: logoImageView.centerYAnchor, constant: -8),
            nameLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 8),

            symbolLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            symbolLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            
            changeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            changeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            priceLabel.bottomAnchor.constraint(equalTo: changeLabel.topAnchor),
            priceLabel.leadingAnchor.constraint(equalTo: changeLabel.leadingAnchor),
        ])
    }

    func configure(with cryptocurrency: Cryptocurrency) {
        nameLabel.text = cryptocurrency.name
        symbolLabel.text = cryptocurrency.symbol
        priceLabel.text = cryptocurrency.price
        changeLabel.text = cryptocurrency.change

        Task{
            if let url = URL(string: cryptocurrency.logo) {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.logoImageView.image = image
                        }
                    }
                }
            }
        }

        addChartView(for: cryptocurrency.symbol)
    }

    private func addChartView(for coin: String) {
        if let chartHostingController = chartHostingController {
            chartHostingController.view.removeFromSuperview()
            chartHostingController.removeFromParent()
        }

        let chartView = ChartViews(coin: coin)
        let hostingController = UIHostingController(rootView: chartView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        addSubview(hostingController.view)
        chartHostingController = hostingController

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: symbolLabel.bottomAnchor, constant: 16),
            hostingController.view.centerXAnchor.constraint(equalTo: centerXAnchor),
            hostingController.view.widthAnchor.constraint(equalToConstant: 168),
            hostingController.view.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
}


class JsonViewController: UIViewController {
    static let zohoPuviFont = UIFont(name: "ZohoPuvi-Medium", size: 20)
    
    private var cryptos: [Cryptocurrency] = [
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

    private var fundsCollectionView: FundsCollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupFundsCollectionView()
    }
    
    private func setupFundsCollectionView() {
        fundsCollectionView = FundsCollectionView()
        fundsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fundsCollectionView)
        
        NSLayoutConstraint.activate([
            fundsCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 300),
            fundsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fundsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            fundsCollectionView.heightAnchor.constraint(equalToConstant: 230)
        ])
        
        fundsCollectionView.configure(with: cryptos)
    }
}

#Preview {
    JsonViewController()
}
