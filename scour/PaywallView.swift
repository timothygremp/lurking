import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                Image("hooded")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .offset(y: 20)
                
                VStack(spacing: 0) {
                    HStack(spacing: 4) {
                        Text("See who is")
                            .foregroundColor(.white)
                        Text("LURKING")
                            .foregroundColor(.red)
                    }
                    .font(.system(size: 32, weight: .bold))
                    
                    Text("near you")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                .multilineTextAlignment(.center)
                .offset(y: -25)
                .padding(.bottom, 10)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Unlock Full Access:")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 4)
                    
                    ForEach(["See what they look like",
                            "See what they did",
                            "See their aliases",
                            "See other addresses"], id: \.self) { text in
                        HStack(spacing: 12) {
                            Text("🐺")
                                .font(.system(size: 22))
                            Text(text)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(white: 0.1))
                .cornerRadius(16)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .offset(y: -30)
                
                ForEach(subscriptionService.products, id: \.id) { product in
                    Button(action: {
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
                    }) {
                        Text(product.subscription?.subscriptionPeriod.unit == .year ? 
                             "Yearly \(product.displayPrice)" : 
                             "Monthly \(product.displayPrice)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }
                .offset(y: -30)
                
                Spacer()
                
                HStack(spacing: 30) {
                    Button("Restore Purchases") {
                        // Handle restore
                    }
                    Button("Privacy Policy") {
                        // Handle privacy
                    }
                    Button("Terms of Use") {
                        // Handle terms
                    }
                }
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .padding(.top, 10)
                .padding(.bottom, 20)
                .offset(y: -40)
            }
            .padding(.top)
            
            // Add loading overlay
            if isLoading {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(true)
                
                GeometryReader { geometry in
                    VStack {
                        Text("🐺")
                            .font(.system(size: 100))
                            .modifier(BreathingModifier())
                        
                        Text("Loading...")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(Color(hex: "282928"))
                    .cornerRadius(20)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        }
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isYearly ? "Annual Membership" : "Monthly Membership")
                            .font(.system(size: 17, weight: .semibold))
                        if isYearly {
                            Text("Save 50%")
                                .font(.system(size: 13))
                                .foregroundColor(.green)
                        }
                    }
                    Spacer()
                    Text(product.displayPrice)
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(isYearly ? Color.red : Color.red.opacity(0.8))
                .cornerRadius(12)
            }
        }
        .disabled(isLoading)
    }
} 