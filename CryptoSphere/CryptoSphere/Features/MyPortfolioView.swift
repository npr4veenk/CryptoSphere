import UIKit

class PortfolioView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "YOUR PORTFOLIO"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .lightGray
        return label
    }()
    
    private let balanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()
    
    private let profitLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.textAlignment = .right
        return label
    }()
    
    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .green
        label.textAlignment = .right
        return label
    }()

    private let withdrawButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "arrow.down.circle.fill")
        config.imagePadding = 10
        config.imagePlacement = .leading
        config.baseForegroundColor = .white
        config.background.backgroundColor = UIColor(white: 1, alpha: 0.1)
        config.cornerStyle = .medium
        config.title = "Withdraw"
        
        let button = UIButton(configuration: config, primaryAction: nil)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let depositButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "arrow.up.circle.fill")
        config.imagePadding = 10
        config.imagePlacement = .leading
        config.baseForegroundColor = .white
        config.background.backgroundColor = UIColor(white: 1, alpha: 0.1)
        config.cornerStyle = .medium
        config.title = "Deposit"
        
        let button = UIButton(configuration: config, primaryAction: nil)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    init() {
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor(white: 1, alpha: 0.1)
        layer.cornerRadius = 20
        clipsToBounds = true
        
        addSubview(titleLabel)
        addSubview(balanceLabel)
        addSubview(profitLabel)
        addSubview(withdrawButton)
        addSubview(depositButton)
        addSubview(percentageLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        profitLabel.translatesAutoresizingMaskIntoConstraints = false
        withdrawButton.translatesAutoresizingMaskIntoConstraints = false
        depositButton.translatesAutoresizingMaskIntoConstraints = false
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            
            balanceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            balanceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            
            profitLabel.topAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            profitLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            
            percentageLabel.centerYAnchor.constraint(equalTo: balanceLabel.centerYAnchor),
            percentageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            
            withdrawButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            withdrawButton.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 10),
            withdrawButton.widthAnchor.constraint(equalToConstant: 160),
            withdrawButton.heightAnchor.constraint(equalToConstant: 40),
            
            depositButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            depositButton.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 10),
            depositButton.widthAnchor.constraint(equalToConstant: 160),
            depositButton.heightAnchor.constraint(equalToConstant: 40),
            
            bottomAnchor.constraint(equalTo: withdrawButton.bottomAnchor, constant: 15)
        ])
    }
    
    func configure(balance: String, profit: String, percentage: String, profitColor: UIColor) {
        balanceLabel.text = balance
        profitLabel.text = profit
        percentageLabel.text = percentage
        percentageLabel.textColor = profitColor
    }
}



class PortfolioViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let portfolioView = PortfolioView()
        portfolioView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(portfolioView)
        
        NSLayoutConstraint.activate([
            portfolioView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            portfolioView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            portfolioView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9)
        ])
        
        portfolioView.configure(balance: "$5,271.39", profit: "+$2,979.23", percentage: "(130.62%)", profitColor: .green)
    }
}

#Preview{
    PortfolioViewController()
}
//    self.scrollView.setContentOffset(offset, animated: false)
//}
