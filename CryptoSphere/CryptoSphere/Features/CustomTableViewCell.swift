import UIKit
import SwiftUI

struct Crypto {
   let name: String
   let symbol: String
   let price: String
   let change: String
   let logo: String
}

class CryptoTableLikeView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate  {
    
    
   // MARK: - UI Elements
   let segmentedControl: UISegmentedControl = {
       let sc = CustomSegmentedControl(items: ["Most Popular", "Trending", "Recommendations"])
       sc.selectedSegmentIndex = 0
       sc.translatesAutoresizingMaskIntoConstraints = false
       return sc
   }()
   
   private let scrollView: UIScrollView = {
       let scrollView = UIScrollView()
       scrollView.isPagingEnabled = true
       scrollView.showsHorizontalScrollIndicator = false
       scrollView.translatesAutoresizingMaskIntoConstraints = false
       return scrollView
   }()
   
   private var mostPopularCollectionView: UICollectionView!
   private var trendingCollectionView: UICollectionView!
   private var recommendedCollectionView: UICollectionView!
   
   private var mostPopularCryptos: [Crypto] = []
   private var trendingCryptos: [Crypto] = []
   private var recommendedCryptos: [Crypto] = []

   // MARK: - Initializers
   override init(frame: CGRect) {
       super.init(frame: frame)
       setupViews()
       loadData()
   }
   
   required init?(coder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
   }
   
   // MARK: - Setup
   private func createCollectionView() -> UICollectionView {
       let layout = UICollectionViewFlowLayout()
       layout.scrollDirection = .vertical
       layout.minimumLineSpacing = 10
       layout.minimumInteritemSpacing = 10
       
       let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
       collectionView.backgroundColor = .black
       collectionView.register(CryptoCollectionViewCell.self, forCellWithReuseIdentifier: "CryptoCell")
       collectionView.translatesAutoresizingMaskIntoConstraints = false
       return collectionView
   }
   
   private func setupViews() {
       backgroundColor = .black
       
       // Add segmented control
       addSubview(segmentedControl)
       
       // Setup scroll view
       addSubview(scrollView)
       scrollView.delegate = self
       
       // Setup collection views
       mostPopularCollectionView = createCollectionView()
       trendingCollectionView = createCollectionView()
       recommendedCollectionView = createCollectionView()
       
       [mostPopularCollectionView, trendingCollectionView, recommendedCollectionView].forEach { collectionView in
           scrollView.addSubview(collectionView!)
           collectionView?.dataSource = self
           collectionView?.delegate = self
       }
       
       setupConstraints()
       
       // Add target for segmented control
       segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
   }
   
   private func setupConstraints() {
       NSLayoutConstraint.activate([
           segmentedControl.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
           segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
           segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
           segmentedControl.heightAnchor.constraint(equalToConstant: 40),
           
           scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
           scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
           scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
           scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
           
           mostPopularCollectionView.topAnchor.constraint(equalTo: scrollView.topAnchor),
           mostPopularCollectionView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
           mostPopularCollectionView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
           mostPopularCollectionView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
           mostPopularCollectionView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
           
           trendingCollectionView.topAnchor.constraint(equalTo: scrollView.topAnchor),
           trendingCollectionView.leadingAnchor.constraint(equalTo: mostPopularCollectionView.trailingAnchor),
           trendingCollectionView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
           trendingCollectionView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
           trendingCollectionView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
           
           recommendedCollectionView.topAnchor.constraint(equalTo: scrollView.topAnchor),
           recommendedCollectionView.leadingAnchor.constraint(equalTo: trendingCollectionView.trailingAnchor),
           recommendedCollectionView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
           recommendedCollectionView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
           recommendedCollectionView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
           recommendedCollectionView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
       ])
   }
   

   // MARK: - Data Loading
   private func loadData() {

           mostPopularCryptos = [
            Crypto(name: "Polygon", symbol: "MATIC", price: "$0.51", change: "-0.02 -0.49%", logo: "p.circle.fill"),
            Crypto(name: "Tether", symbol: "USDT", price: "$1.1", change: "+0.1 +0.1%", logo: "t.circle.fill"),
            Crypto(name: "Chainlink", symbol: "LINK", price: "$7.72", change: "-0.05 -0.72%", logo: "c.circle.fill"),
        ]
           
           trendingCryptos = [
            Crypto(name: "Polygon", symbol: "MATIC", price: "$0.51", change: "-0.02 -0.49%", logo: "p.circle.fill"),
            Crypto(name: "Tether", symbol: "USDT", price: "$1.1", change: "+0.1 +0.1%", logo: "t.circle.fill"),
            Crypto(name: "Chainlink", symbol: "LINK", price: "$7.72", change: "-0.05 -0.72%", logo: "c.circle.fill"),
        ]
           
           recommendedCryptos = [
            Crypto(name: "Polygon", symbol: "MATIC", price: "$0.51", change: "-0.02 -0.49%", logo: "p.circle.fill"),
            Crypto(name: "Tether", symbol: "USDT", price: "$1.1", change: "+0.1 +0.1%", logo: "t.circle.fill"),
            Crypto(name: "Chainlink", symbol: "LINK", price: "$7.72", change: "-0.05 -0.72%", logo: "c.circle.fill"),
        ]
           
        DispatchQueue.main.async {
            self.mostPopularCollectionView.reloadData()
            self.trendingCollectionView.reloadData()
            self.recommendedCollectionView.reloadData()
        }
   }
       
   
   
// MARK: - UICollectionViewDataSource
       func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
           switch collectionView {
           case mostPopularCollectionView:
               return mostPopularCryptos.count
           case trendingCollectionView:
               return trendingCryptos.count
           case recommendedCollectionView:
               return recommendedCryptos.count
           default:
               return 0
           }
       }
       
       func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
           let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CryptoCell", for: indexPath) as! CryptoCollectionViewCell
           
           switch collectionView {
           case mostPopularCollectionView:
               cell.configure(with: mostPopularCryptos[indexPath.item])
           case trendingCollectionView:
               cell.configure(with: trendingCryptos[indexPath.item])
           case recommendedCollectionView:
               cell.configure(with: recommendedCryptos[indexPath.item])
           default:
               break
           }
           
           cell.layer.cornerRadius = 25
           return cell
       }
   
   
// MARK: - UICollectionViewDelegateFlowLayout
   func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
       return CGSize(width: collectionView.frame.width - 32, height: 70)
   }
   
   
// MARK: - UIScrollViewDelegate
   func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
       let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
       segmentedControl.selectedSegmentIndex = page
   }
   
// MARK: - Actions
    @objc func segmentChanged(_ sender: UISegmentedControl) {
       let selectedIndex = CGFloat(sender.selectedSegmentIndex)
       let offset = CGPoint(x: scrollView.bounds.width * selectedIndex, y: 0)
       scrollView.setContentOffset(offset, animated: true)
   }
}



class CryptoCollectionViewCell: UICollectionViewCell {
   // UI Elements
   private let logoImageView: UIImageView = {
       let imageView = UIImageView()
       imageView.tintColor = .white
//        imageView.backgroundColor = .black
       imageView.layer.cornerRadius = 25
       imageView.clipsToBounds = true
       imageView.contentMode = .scaleAspectFill
       imageView.translatesAutoresizingMaskIntoConstraints = false
       return imageView
   }()
   
   private let nameLabel: UILabel = {
       let label = UILabel()
       label.font = UIFont.boldSystemFont(ofSize: 20)
       label.textColor = .white
       label.translatesAutoresizingMaskIntoConstraints = false
       return label
   }()
   
   private let symbolLabel: UILabel = {
       let label = UILabel()
       label.font = UIFont.systemFont(ofSize: 12)
       label.textColor = .gray
       label.translatesAutoresizingMaskIntoConstraints = false
       return label
   }()
   
   private let priceLabel: UILabel = {
       let label = UILabel()
       label.font = UIFont.boldSystemFont(ofSize: 16)
       label.textColor = .white
       label.textAlignment = .right
       label.translatesAutoresizingMaskIntoConstraints = false
       return label
   }()
   
   private let changeLabel: UILabel = {
       let label = UILabel()
       label.font = UIFont.systemFont(ofSize: 14)
       label.textColor = .white
       label.textAlignment = .right
       label.translatesAutoresizingMaskIntoConstraints = false
       return label
   }()
   
   var chartHostingController: UIHostingController<ChartViews>?

   override init(frame: CGRect) {
       super.init(frame: frame)
       setupViews()
   }

   required init?(coder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
   }

   private func setupViews() {
       backgroundColor = .greyBackgroundDarkMode
       contentView.addSubview(logoImageView)
       contentView.addSubview(nameLabel)
       contentView.addSubview(symbolLabel)
       contentView.addSubview(priceLabel)
       contentView.addSubview(changeLabel)
       

       NSLayoutConstraint.activate([
           logoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
           logoImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
           logoImageView.widthAnchor.constraint(equalToConstant: 47),
           logoImageView.heightAnchor.constraint(equalToConstant: 47),
           
           nameLabel.topAnchor.constraint(equalTo: logoImageView.topAnchor, constant: 2),
           nameLabel.widthAnchor.constraint(equalToConstant: 100),
           nameLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 8),

           symbolLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
           symbolLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
           
           priceLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
           priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
           
           changeLabel.topAnchor.constraint(equalTo: symbolLabel.topAnchor),
           changeLabel.trailingAnchor.constraint(equalTo: priceLabel.trailingAnchor),
       ])
   }

   func configure(with crypto: Crypto) {
       nameLabel.text = crypto.name
       symbolLabel.text = crypto.symbol
       priceLabel.text = crypto.price
       changeLabel.text = crypto.change
       changeLabel.textColor = crypto.change.contains("-") ? .red : .green
//        logoImageView.image = UIImage(systemName: crypto.logo)3
       Task{
           if let url = try await URL(string: CoinDetailsResponse().fetchOneCoinDetails(symbol: String(crypto.symbol.dropLast(4))).imageUrl) {
               if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                   self.logoImageView.image = image
               }
               print(crypto.symbol.dropLast(4))
           }
       }
       addChartView(for: crypto.symbol)
   }
   
   private func addChartView(for coin: String) {
       if let chartHostingController = chartHostingController {
           chartHostingController.view.removeFromSuperview()
           chartHostingController.removeFromParent()
       }

       let chartView = ChartViews(coin: coin, lineWidth: 2)
       let hostingController = UIHostingController(rootView: chartView)
       hostingController.view.translatesAutoresizingMaskIntoConstraints = false
       hostingController.view.backgroundColor = .clear
       contentView.addSubview(hostingController.view)
       chartHostingController = hostingController

       NSLayoutConstraint.activate([
           hostingController.view.topAnchor.constraint(equalTo: nameLabel.centerYAnchor, constant: 0),
           hostingController.view.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 2),
           hostingController.view.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -10),
           hostingController.view.heightAnchor.constraint(equalToConstant: 20),
           hostingController.view.widthAnchor.constraint(equalToConstant: 70),
       ])
   }
}

class CustomSegmentedControl: UISegmentedControl {
   private let selectionIndicator = UIView()

   override init(items: [Any]?) {
       super.init(items: items)
       setupSegmentedControl()
   }

   required init?(coder: NSCoder) {
       super.init(coder: coder)
       setupSegmentedControl()
   }

   private func setupSegmentedControl() {

       self.backgroundColor = .clear
       self.selectedSegmentTintColor = .clear
       self.setTitleTextAttributes([.foregroundColor: UIColor.lightGray, .font: UIFont.systemFont(ofSize: 14)], for: .normal)
       self.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.boldSystemFont(ofSize: 15)], for: .selected)
//        self.setWidth(40, forSegmentAt: 2)
       
       self.setBackgroundImage(UIImage(), for: .normal, barMetrics: .default)
       self.setBackgroundImage(UIImage(), for: .selected, barMetrics: .default)
       self.setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)

       

       // Add selection indicator
       selectionIndicator.backgroundColor = .white
       selectionIndicator.layer.cornerRadius = 2
       self.addSubview(selectionIndicator)
   }

   override func layoutSubviews() {
       super.layoutSubviews()
       updateSelectionIndicator()
   }

   private func updateSelectionIndicator() {
       let segmentWidth = self.bounds.width / CGFloat(self.numberOfSegments)
       let indicatorHeight: CGFloat = 2
       let indicatorY = self.bounds.height - indicatorHeight

       UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
           self.selectionIndicator.frame = CGRect(
               x: segmentWidth * CGFloat(self.selectedSegmentIndex),
               y: indicatorY,
               width: segmentWidth,
               height: indicatorHeight
           )
       }
   }
}


// MARK: - CryptoViewController
class CryptoViewController: UIViewController {
   private let cryptoView = CryptoTableLikeView()

   override func viewDidLoad() {
       super.viewDidLoad()
       view.backgroundColor = .black
       setupCryptoView()
   }
   
   private func setupCryptoView() {
       view.addSubview(cryptoView)
       cryptoView.translatesAutoresizingMaskIntoConstraints = false
       
       NSLayoutConstraint.activate([
           cryptoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 400),
           cryptoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
           cryptoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
           cryptoView.heightAnchor.constraint(equalToConstant: 400)
       ])
   }
}

#Preview {
   CryptoViewController()
}
