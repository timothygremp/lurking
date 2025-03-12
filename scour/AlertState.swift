import SwiftUI

class AlertState: ObservableObject {
    @Published var showingError = false
    @Published var errorMessage: String?
    
    static let shared = AlertState()
    
    func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    func clearError() {
        errorMessage = nil
        showingError = false
    }
} 