import Foundation
import StoreKit

@MainActor
class SubscriptionService: ObservableObject {
    @Published var isSubscribed = false
    @Published var products: [Product] = []
    @Published var purchaseError: String?
    
    static let shared = SubscriptionService()
    private var updateListenerTask: Task<Void, Error>?
    
    private let productID = "lurk_199"  // Changed to single product ID
    
    private init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updatePurchaseStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
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
            if transaction.productID == productID {
                await self.updatePurchaseStatus()
            }
            await transaction.finish()
        case .unverified:
            break
        }
    }
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [productID])
            self.products = products
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updatePurchaseStatus()
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
    
    func updatePurchaseStatus() async {
        print("Checking purchase status...")
        
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == productID {
                    print("Found valid purchase")
                    DispatchQueue.main.async {
                        self.isSubscribed = true
                        UserDefaults.standard.set(true, forKey: "isSubscribed")
                    }
                    return
                }
            case .unverified:
                continue
            }
        }
        
        print("No valid purchase found")
        DispatchQueue.main.async {
            self.isSubscribed = false
            UserDefaults.standard.set(false, forKey: "isSubscribed")
        }
    }
    
    func checkSubscription() -> Bool {
        isSubscribed
    }
    
    func restorePurchases() async throws {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == productID {
                    print("Found valid restored purchase")
                    DispatchQueue.main.async {
                        self.isSubscribed = true
                        UserDefaults.standard.set(true, forKey: "isSubscribed")
                    }
                    return
                }
            case .unverified:
                throw SubscriptionError.verificationFailed
            }
        }
        throw SubscriptionError.productNotFound
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