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
    
    pri