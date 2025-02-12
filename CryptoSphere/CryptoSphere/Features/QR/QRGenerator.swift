import UIKit
import CoreImage.CIFilterBuiltins

class QRCodeView: UIView {
    // MARK: - UI Elements
    private let qrImageView = UIImageView()

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .white
        
        // Configure the UIImageView
        qrImageView.contentMode = .scaleAspectFit
        qrImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(qrImageView)
        
        // Add constraints to center the UIImageView
        NSLayoutConstraint.activate([
            qrImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            qrImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            qrImageView.widthAnchor.constraint(equalToConstant: 200),
            qrImageView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    // MARK: - Public Method
    func generateQRCode(from string: String) {
        if let qrImage = generateQRCodeImage(from: string) {
            qrImageView.image = qrImage
        } else {
            print("Failed to generate QR code")
        }
    }
    
    // MARK: - Private Method
    private func generateQRCodeImage(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        
        if let outputImage = filter.outputImage {
            let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10)) // Scale up the image
            return UIImage(ciImage: transformedImage)
        }
        return nil
    }
}

class QRCodeViewController: UIViewController {
    private let qrCodeView = QRCodeView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupQRCodeView()
        
        // Generate and display the QR code
        qrCodeView.generateQRCode(from: "Hello")
    }
    
    private func setupQRCodeView() {
        view.backgroundColor = .white
        
        // Add the QRCodeView to the view controller
        view.addSubview(qrCodeView)
        qrCodeView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add constraints to fill the view
        NSLayoutConstraint.activate([
            qrCodeView.topAnchor.constraint(equalTo: view.topAnchor),
            qrCodeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            qrCodeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            qrCodeView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

#Preview {
    QRCodeViewController()
}
