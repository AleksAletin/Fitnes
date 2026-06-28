import SwiftUI

// Кольцо пакета: остаток как главная метрика, дуга по доле проведённых.
struct PackageRing: View {
    let client: Client
    let yellowThreshold: Int
    var size: CGFloat = 120

    private var package: Package? { client.package }

    private var fraction: Double {
        guard let package, package.total > 0 else { return 0 }
        return min(1, max(0, Double(package.used) / Double(package.total)))
    }

    private var state: SemaphoreState {
        client.semaphore(yellowThreshold: yellowThreshold)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appBackground, lineWidth: 12)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(state.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                if client.debt > 0 {
                    Text("\(client.debt)")
                        .font(.system(size: size * 0.32, weight: .bold))
                        .foregroundStyle(Color.semRed)
                    Text("в долг")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.semRed)
                } else if let package {
                    Text("\(package.remaining)")
                        .font(.system(size: size * 0.34, weight: .bold))
                        .foregroundStyle(Color.appText)
                    Text("из \(package.total)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appSecondary)
                } else {
                    Text("—")
                        .font(.system(size: size * 0.34, weight: .bold))
                        .foregroundStyle(Color.appSecondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}
