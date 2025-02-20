import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🔒")
                .font(.system(size: 60))
            
            Text("Subscribe to Access")
                .font(.title)
                .foregroundColor(.white)
            
            Text("View offender photos and detailed crime information")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            // Subscription options
            VStack(spacing: 12) {
                ForEach(subscriptionService.products, id: \.id) { product in
                    SubscriptionButton(
                        product: product,
                        isLoading: isLoading,
                        action: {
                            Task {
                                isLoading = true
                                do {
                                    try await subscriptionService.purchase(product)
                                    isLoading = false
                                    dismiss()
                                } catch SubscriptionService.SubscriptionError.userCancelled {
                                    isLoading = false
                                } catch {
                                    isLoading = false
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            Button(action: {
                dismiss()
            }) {
                Text("Maybe Later")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(hex: "1C1C1E"))
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            await subscriptionService.loadProducts()
        }
    }
}

struct SubscriptionButton: View {
    let product: Product
    let isLoading: Bool
    let action: () -> Void
    
    var isYearly: Bool {
        product.subscription?.subscriptionPeriod.unit == .year
    }
    
    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text(isYearly ? "Annual Plan" : "Monthly Plan")
                            .font(.headline)
                        if isYearly {
                            Text("Save up to 50%")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                    Spacer()
                    Text(product.displayPrice)
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isYearly ? Color.red : Color.red.opacity(0.8))
                .cornerRadius(10)
            }
        }
        .disabled(isLoading)
    }
} 