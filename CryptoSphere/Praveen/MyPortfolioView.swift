import UIKit
import SwiftUI

class PortfolioView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "YOUR PORTFOLIO"
        label.font = Fonts.getPuviFont("medium", 14)
        label.textColor = .secondaryFont
        return label
    }()
    
    private let balanceLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.getPuviFont("bold", 32)
        label.textColor = .font
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()
    
    private let profitLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.getPuviFont("medium", 14)
        label.textColor = .font
        label.textAlignment = .right
        return label
    }()
    
    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.getPuviFont("medium", 16)
        label.textColor = .green
        label.textAlignment = .right
        return label
    }()

    private let receiveButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        let image = UIImage(systemName: "arrow.down.circle.fill", withConfiguration: config)
        
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.alignment = .center
        
        let imageView = UIImageView(image: image)
        imageView.tintColor = .font
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = "Receive"
        label.font = Fonts.getPuviFont("medium", 16)
        label.textColor = .font
        
        buttonStack.addArrangedSubview(imageView)
        buttonStack.addArrangedSubview(label)
        
        button.addSubview(buttonStack)
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonStack.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            buttonStack.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        button.layer.cornerRadius = 20
        button.backgroundColor = .font.withAlphaComponent(0.2)
        
        return button
    }()

    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        let image = UIImage(systemName: "arrow.up.circle.fill", withConfiguration: config)
        
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.alignment = .center
        
        let imageView = UIImageView(image: image)
        imageView.tintColor = .font
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = "Send"
        label.font = Fonts.getPuviFont("medium", 16)
        label.textColor = .font
        
        buttonStack.addArrangedSubview(imageView)
        buttonStack.addArrangedSubview(label)
        
        button.addSubview(buttonStack)
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonStack.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            buttonStack.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        button.layer.cornerRadius = 20
        button.backgroundColor = .font.withAlphaComponent(0.2)
        
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
        backgroundColor = .font.withAlphaComponent(0.1)
        layer.cornerRadius = 20
        clipsToBounds = true
        
        addSubview(titleLabel)
        addSubview(balanceLabel)
        addSubview(profitLabel)
        addSubview(receiveButton)
        addSubview(sendButton)
        addSubview(percentageLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        profitLabel.translatesAutoresizingMaskIntoConstraints = false
        receiveButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false
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
            
            receiveButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            receiveButton.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 10),
            receiveButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width/2.5),
            receiveButton.heightAnchor.constraint(equalToConstant: 38),
            
            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            sendButton.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 10),
            sendButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width/2.45),
            sendButton.heightAnchor.constraint(equalToConstant: 38),
            
            bottomAnchor.constraint(equalTo: receiveButton.bottomAnchor, constant: 15)
        ])
        
        setUpActions()
    }
    
    func setUpActions(){
        receiveButton.addTarget(self, action: #selector(receiveButtonTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
    }
    
    
    
    func configure(balance: String, profit: String, percentage: String, profitColor: UIColor, receiveAction: @escaping () -> Void, sendAction: @escaping () -> Void) {
        balanceLabel.text = formatBalance(Double(balance) ?? 200)
        profitLabel.text = profit
        percentageLabel.text = percentage
        percentageLabel.textColor = profitColor
        
        // Assign actions
        self.receiveButtonTapAction = receiveAction
        self.sendButtonTapAction = sendAction
    }
    
    func formatBalance(_ balance: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        switch balance {
        case 1_000_000_000_000...:
            return "$" + formatter.string(from: NSNumber(value: balance / 1_000_000_000_000))! + "T"
        case 1_000_000_000...:
            return "$" + formatter.string(from: NSNumber(value: balance / 1_000_000_000))! + "B"
        case 1_000_000...:
            return "$" + formatter.string(from: NSNumber(value: balance / 1_000_000))! + "M"
        case 1_000...:
            return "$" + formatter.string(from: NSNumber(value: balance / 1_000))! + "K"
        default:
            return "$" + formatter.string(from: NSNumber(value: balance))!
        }
    }

    @objc private func receiveButtonTapped() {
        receiveButtonTapAction?()
    }

    @objc private func sendButtonTapped() {
        sendButtonTapAction?()
    }

    // Properties to hold the actions
    private var receiveButtonTapAction: (() -> Void)?
    private var sendButtonTapAction: (() -> Void)?
}



class PortfolioViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        let portfolioView = PortfolioView()
        portfolioView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(portfolioView)
        
        NSLayoutConstraint.activate([
            portfolioView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            portfolioView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            portfolioView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9)
        ])
        
        portfolioView.configure(
            balance: "Your Balance",
            profit: "Your Profit",
            percentage: "Your Percentage",
            profitColor: .green,
            receiveAction: { [weak self] in
                self?.receiveButtonTapped()
            },
            sendAction: { [weak self] in
                self?.sendButtonTapped()
            }
        )
    }
    
    private func receiveButtonTapped(){
//        print("Receive Button Tapped!")
    }
    
    private func sendButtonTapped(){
//        print("Send Button Tapped!")
    }
}

#Preview{
    PortfolioViewController()
}
//    self.scrollView.setContentOffset(offset, animated: false)
//}
