//
//  ViewController.swift
//  starling
//
//  Created by Сергей Бочков on 24.01.2026.
//
// Final version for review
import UIKit

class ViewController: UIViewController {
    
    private let amountLabel = UILabel()
    private let titleLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        let manager = StarlingManager()
        
        Task {
            do {
                let accounts = try await manager.fetchAccounts()
                guard let account = accounts.first else { return }
                
                let transactions = try await manager.fetchTransactions(
                    account: account.accountUid,
                    category: account.defaultCategory
                )
                
                let totalPence = manager.calculateRoundUp(from: transactions)
                let pounds = Double(totalPence) / 100.0
                
                await MainActor.run {
                    self.amountLabel.text = String(format: "£%.2f", pounds)
                }
                
            } catch {
                print("❌ Error: \(error)")
            }
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        titleLabel.text = "Your Round Up"
        titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        
        amountLabel.text = "£0.00"
        amountLabel.font = .systemFont(ofSize: 48, weight: .bold)
        amountLabel.textAlignment = .center
        amountLabel.textColor = .black
        
        
        [titleLabel, amountLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            amountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            amountLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            titleLabel.bottomAnchor.constraint(equalTo: amountLabel.topAnchor, constant: -10),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}

