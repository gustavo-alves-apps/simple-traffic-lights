import Foundation
import StoreKit

@MainActor
final class TipStore: ObservableObject {
    static let productIDs = [
        "com.gustavo.trafficlight.tip1",
        "com.gustavo.trafficlight.tip2",
        "com.gustavo.trafficlight.tip3"
    ]

    @Published private(set) var products: [Product] = []
    @Published var alertMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func load() async {
        do {
            let loaded = try await Product.products(for: Self.productIDs)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            products = []
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    alertMessage = "Thank you! ☕"
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            alertMessage = "Something went wrong. Please try again."
        }
    }
}
