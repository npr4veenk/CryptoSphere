import SwiftUI
import UIKit

class CustomLoadingView: UIView {
    private let hostingController: UIHostingController<LoadingView>

    override init(frame: CGRect) {
        self.hostingController = UIHostingController(rootView: LoadingView())
        super.init(frame: frame)
        setupLoadingView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLoadingView() {
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 40)
        ])
    }

    func show() {
        self.isHidden = false
        self.alpha = 1.0
        
    }

    func hide() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0.0
        } completion: { _ in
            self.isHidden = true
        }
    }

    func hideAfter(seconds: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.hide()
        }
    }
}

// SwiftUI Preview Wrapper for UIView
struct CustomLoadingViewPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> CustomLoadingView {
        let view = CustomLoadingView(frame: UIScreen.main.bounds)
        return view
    }

    func updateUIView(_ uiView: CustomLoadingView, context: Context) { }
}

#Preview {
    CustomLoadingViewPreview()
}
