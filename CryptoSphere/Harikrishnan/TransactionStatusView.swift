//
//  TransactionStatusView.swift
//  CryptoSphere
//
//  Created by Harikrishnan V on 2025-03-17.
//
import SwiftUI

struct TransactionStatusView: View {
    enum Status {
        case success(amount: Double, recipient: String)
        case error(message: String)
    }
    
    let status: Status
    var onDismiss: () -> Void
    var onRetry: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                statusIcon
                statusContent
                actionButtons
            }
            .padding(24)
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        Group {
            if case .success = status {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.red)
            }
        }
        .font(.system(size: 64))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var statusContent: some View {
        VStack(spacing: 12) {
            Group {
                if case .success(let amount, let recipient) = status {
                    Text("Transaction Successful")
                        .font(.title2.bold())
                    Text("\(amount.formatted(.currency(code: "USD")))")
                        .font(.largeTitle.bold())
                    Text("to \(recipient)")
                        .foregroundColor(.secondary)
                } else if case .error(let message) = status {
                    Text("Transaction Failed")
                        .font(.title2.bold())
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
            }
            .transition(.opacity)
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if case .success = status {
                Button("Done", action: onDismiss)
                    .primaryActionButton()
            } else {
                if let onRetry {
                    Button("Retry Transaction", action: onRetry)
                        .primaryActionButton()
                }
                Button("Back to Wallet", action: onDismiss)
                    .secondaryActionButton()
            }
        }
        .padding(.top)
    }
}

// MARK: - Button Styles
extension View {
    func primaryActionButton() -> some View {
        self
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.primaryTheme)
            .cornerRadius(12)
    }
    
    func secondaryActionButton() -> some View {
        self
            .font(.subheadline)
            .foregroundColor(.primary)
            .padding(8)
    }
}

// MARK: - Preview
#Preview {
    Group {
        TransactionStatusView(
            status: .success(amount: 149.99, recipient: "John Doe"),
            onDismiss: {}
        )
        
        TransactionStatusView(
            status: .error(message: "Insufficient funds to complete transaction"),
            onDismiss: {},
            onRetry: {}
        )
    }
}
