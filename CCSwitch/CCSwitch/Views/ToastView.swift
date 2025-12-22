import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Material.ultraThin)
        .cornerRadius(20)
        .shadow(radius: 4)
        .padding(.top, 10)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let type: ToastType
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if isPresented {
                ToastView(message: message, type: type)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                isPresented = false
                            }
                        }
                    }
            }
        }
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, type: ToastType = .success) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, type: type))
    }
}