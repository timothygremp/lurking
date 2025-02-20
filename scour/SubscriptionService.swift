import Foundation
import StoreKit

@MainActor
class SubscriptionService: ObservableObject {
    @Published var isSubscribed = false
    @Published var products: [Product] = []
    @Published var purchaseError: String?
    
    static let shared = SubscriptionService()
    private var updateListenerTask: Task<Void, Error>?
    private var backgroundObserver: Any?
    private var periodicCheckTask: Task<Void, Never>?
    
    private let productIDs = [
        "mm_499_1m",  // Replace with your actual monthly product ID
        "mm_2999_1yr"    // Replace with your actual yearly product ID
    ]
    
    private init() {
        setupBackgroundCheck()
        setupPeriodicCheck()
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        updateListenerTask?.cancel()
        periodicCheckTask?.cancel()
    }
    
    private func setupBackgroundCheck() {
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.updateSubscriptionStatus()
            }
        }
    }
    
    private func setupPeriodicCheck() {
        periodicCheckTask = Task {
            while !Task.isCancelled {
                await updateSubscriptionStatus()
                try? await Task.sleep(nanoseconds: 3600 * 1_000_000_000) // 1 hour
            }
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                await self.handle(updatedTransaction: result)
            }
        }
    }
    
    private func handle(updatedTransaction result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            if self.productIDs.contains(transaction.productID) {
                await self.updateSubscriptionStatus()
            }
            await transaction.finish()
        case .unverified:
            break
        }
    }
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: productIDs)
            // Sort products by price (monthly first)
            self.products = products.sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Check if the transaction is verified
                switch verification {
                case .verified(let transaction):
                    // Update the user's subscription status
                    await transaction.finish()
                    await updateSubscriptionStatus()
                case .unverified:
                    throw SubscriptionError.verificationFailed
                }
            case .userCancelled:
                throw SubscriptionError.userCancelled
            case .pending:
                throw SubscriptionError.pending
            @unknown default:
                throw SubscriptionError.unknown
            }
        } catch {
            throw error
        }
    }
    
    func updateSubscriptionStatus() async {
        print("Checking subscription status...")
        var foundValidSubscription = false
        
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                print("Found transaction: \(transaction.productID)")
                print("Transaction status - isUpgraded: \(transaction.isUpgraded)")
                print("Transaction expiration date: \(transaction.expirationDate ?? Date())")
                
                if productIDs.contains(transaction.productID) && 
                   !transaction.isUpgraded {
                    if let expirationDate = transaction.expirationDate,
                       expirationDate > Date() {
                        print("Found valid subscription that expires: \(expirationDate)")
                        foundValidSubscription = true
                        DispatchQueue.main.async {
                            self.isSubscribed = true
                            UserDefaults.standard.set(true, forKey: "isSubscribed")
                        }
                        return
                    } else {
                        print("Found expired subscription")
                    }
                }
            case .unverified(let transaction, let error):
                print("Unverified transaction: \(error.localizedDescription)")
                continue
            }
        }
        
        if !foundValidSubscription {
            print("No valid subscription found")
            DispatchQueue.main.async {
                self.isSubscribed = false
                UserDefaults.standard.set(false, forKey: "isSubscribed")
            }
        }
    }
    
    func checkSubscription() -> Bool {
        isSubscribed
    }
    
    enum SubscriptionError: Error {
        case productNotFound
        case purchaseFailed
        case verificationFailed
        case userCancelled
        case pending
        case unknown
    }
} 