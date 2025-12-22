import SwiftUI

enum ToastType {
    case success
    case info
    case error
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .info: return .blue
        case .error: return .red
        }
    }
}

class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var isPresented = false
    @Published var message = ""
    @Published var type: ToastType = .success
    
    private init() {}
    
    func show(message: String, type: ToastType = .success) {
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
    
    private func present(message: String, type: ToastType) {
        self.message = message
        self.type = type
        withAnimation {
            self.isPresented = true
        }
    }
}