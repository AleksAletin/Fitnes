import SwiftUI

// Тост «Готово · Отменить» с автоскрытием (DEV_BRIEF §6.3–6.5, §9).
@MainActor
final class ToastCenter: ObservableObject {
    @Published var message: String?
    private var undoAction: (() -> Void)?
    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, undo: @escaping () -> Void) {
        self.message = message
        self.undoAction = undo
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self?.clear()
        }
    }

    func performUndo() {
        undoAction?()
        clear()
    }

    func clear() {
        dismissTask?.cancel()
        message = nil
        undoAction = nil
    }
}

// Вид тоста, накладывается у корня приложения.
struct ToastView: View {
    @EnvironmentObject private var toasts: ToastCenter

    var body: some View {
        VStack {
            Spacer()
            if let message = toasts.message {
                HStack(spacing: 14) {
                    Text(message)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(uiColor: .systemBackground))
                    Spacer(minLength: 8)
                    Button("Отменить") { toasts.performUndo() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x9D9BFF))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Color(uiColor: .label), in: Capsule())
                .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                .padding(.horizontal, 16)
                .padding(.bottom, 60)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toasts.message)
        .allowsHitTesting(toasts.message != nil)
    }
}
