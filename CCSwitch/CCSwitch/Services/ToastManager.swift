import SwiftUI

class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var isPresented = false
    @Published var message = ""
    @Published var type: ToastView.ToastType = .success
    
    private init() {}
    
    func show(message: String, type: ToastView.ToastType = .success) {
        // If a toast is already showing, hide it first to reset the timer and animation
        if isPresented {
            isPresented = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.present(message: message, type: type)
            }
        } else {
            present(message: message, type: type)
        }
    }
    
    private func present(message: String, type: ToastView.ToastType) {
        self.message = message
        self.type = type
        withAnimation {
            self.isPresented = true
        }
    }
}
