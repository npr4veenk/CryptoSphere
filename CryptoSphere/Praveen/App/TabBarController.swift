//
//  MainTabBarController.swift
//  CryptoSphere
//
//  Created by Praveenkumar Narayanamoorthy on 30/01/25.
//

import UIKit
import SwiftUI

class MainTabBarController: UITabBarController {
    
    private let tradeButton: UIButton = {
        let button = UIButton(type: .custom)
        let tradeImage = UIImage(systemName: "arrow.left.arrow.right.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 46, weight: .medium))
            .withRenderingMode(.alwaysOriginal) // Prevents tint from altering background

        button.setImage(tradeImage, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 80 // Half of 50 to match image size
        button.tintColor = .primaryTheme
//        button.layer.masksToBounds = true
        button.layer.shadowColor = UIColor.clear.cgColor

        return button
    }()
    private let clickedTradeButton: UIButton = {
        let button = UIButton(type: .custom)
        let tradeImage = UIImage(systemName: "arrow.left.arrow.right.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 46, weight: .medium))
            .withRenderingMode(.alwaysOriginal) // Prevents tint from altering background

        button.setImage(tradeImage, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 80
        button.tintColor = .primaryTheme
//        button.layer.masksToBounds = true
        button.layer.shadowColor = UIColor.clear.cgColor

        return button
    }()
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        setupTabBar()
        setupTradeButton()
    }
    
    private func setupTabBar() {
        let homeVC = UINavigationController(rootViewController: HomeViewController())
        homeVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house.fill"), tag: 0)

        let marketsVC = UINavigationController(rootViewController: UIHostingController(rootView: CoinsListView(dismiss: false, isMarket: true)))
        marketsVC.tabBarItem = UITabBarItem(title: "Markets", image: UIImage(systemName: "chart.bar.fill"), tag: 1)

        let tradeMainVC = UINavigationController(rootViewController: TradeViewController())

        let walletVC = UINavigationController(rootViewController: UIHostingController(rootView: WalletView()))
        walletVC.tabBarItem = UITabBarItem(title: "Wallet", image: UIImage(systemName: "wallet.bifold.fill"), tag: 3)

        let accountVC = UINavigationController(rootViewController: UIHostingController(rootView: AccountView()))
        accountVC.tabBarItem = UITabBarItem(title: "Account", image: UIImage(systemName: "person.crop.circle.fill"), tag: 4)

        self.viewControllers = [homeVC, marketsVC, tradeMainVC, walletVC, accountVC]

        // Configure tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.background

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance

        // Remove the separator line
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()

        // Other customizations
        tabBar.tintColor = UIColor.primaryTheme
        tabBar.unselectedItemTintColor = UIColor.secondaryFont
        tabBar.isTranslucent = false

        // Remove blur effect if any
        tabBar.subviews.forEach { subview in
            if subview is UIVisualEffectView {
                subview.removeFromSuperview()
            }
        }

        // Customize tab bar font
        let fontAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        UITabBarItem.appearance().setTitleTextAttributes(fontAttributes, for: .normal)
    }


    
    private func setupTradeButton() {
        tradeButton.addTarget(self, action: #selector(tradeButtonTapped), for: .touchUpInside)
        
        view.addSubview(tradeButton)
        tradeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tradeButton.centerXAnchor.constraint(equalTo: tabBar.centerXAnchor),
            tradeButton.centerYAnchor.constraint(equalTo: tabBar.topAnchor, constant: 26),
            tradeButton.widthAnchor.constraint(equalToConstant: 60),
            tradeButton.heightAnchor.constraint(equalToConstant: 60)
        ])

    }

    @objc private func tradeButtonTapped() {
        animateTradeButton()
        
        if let viewControllers = self.viewControllers, viewControllers.count > 2 {
            let targetVC = viewControllers[2] // Trade tab
            
            // Apply the same transition effect as normal tab switching
            self.tabBarController(self, shouldSelect: targetVC)
            self.selectedIndex = 2
        }
    }

    private func animateTradeButton() {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.toValue = CGFloat.pi
        rotationAnimation.duration = 0.5 // Adjust speed as needed
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        tradeButton.layer.add(rotationAnimation, forKey: "rotationAnimation")
    }



}

// MARK: - Smooth Tab Bar Transitions
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let fromView = selectedViewController?.view,
              let toView = viewController.view,
              let fromIndex = viewControllers?.firstIndex(of: selectedViewController!),
              let toIndex = viewControllers?.firstIndex(of: viewController),
              fromIndex != toIndex else {
            return true
        }
        
        let direction: CGFloat = toIndex > fromIndex ? 1 : -1
        
        toView.frame = fromView.frame.offsetBy(dx: direction * fromView.frame.width, dy: 0)
        tabBarController.view.insertSubview(toView, aboveSubview: fromView)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            fromView.frame = fromView.frame.offsetBy(dx: -direction * fromView.frame.width, dy: 0)
            toView.frame = fromView.frame
        } completion: { finished in
            if finished {
                fromView.frame = fromView.frame
            }
        }
        return true
    }
}
