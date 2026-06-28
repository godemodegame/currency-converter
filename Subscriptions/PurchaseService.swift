//
//  PurchaseService.swift
//  Subscriptions
//
//  Created by Kirill Kirilenko on 01/05/2023.
//

import Combine
import Foundation
import StoreKit

/// Errors surfaced by `PurchaseService.purchase(_:)`.
public enum PurchaseError: Error {
    /// The user dismissed the purchase sheet.
    case cancelled
    /// StoreKit could not verify the transaction's signature.
    case unverified(Error)
}

@MainActor
public final class PurchaseService: ObservableObject {
    // MARK: Private properties
    private let productsId: [String]

    @Published
    public private(set) var products: [Product] = []
    private var productsLoaded = false

    @Published
    public private(set) var error: Error?
    private var updates: Task<Void, Never>? = nil

    @Published
    public private(set) var purchasedProductIDs = Set<String>()

    // MARK: Public properties

    public var hasUnlockedPro: Bool {
        !purchasedProductIDs.isEmpty
    }

    // MARK: Lifecycle

    public init(productsId: [String]) {
        self.productsId = productsId
        updates = observeTransactionUpdates()
    }

    deinit {
        updates?.cancel()
    }

    // MARK: Public methods

    public func loadProducts() async {
        guard !productsLoaded else {
            return
        }
        do {
            let loadedProducts = try await Product.products(for: productsId)
            products = loadedProducts
            productsLoaded = productsId.isEmpty || !loadedProducts.isEmpty
        } catch {
            self.error = error
        }
        
    }

    public func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case let .success(.verified(transaction)):
            await transaction.finish()
            await updatePurchasedProducts()
        case let .success(.unverified(_, error)):
            throw PurchaseError.unverified(error)
        case .pending:
            break
        case .userCancelled:
            throw PurchaseError.cancelled
        @unknown default:
            break
        }
    }

    public func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.revocationDate == nil {
                purchasedProductIDs.insert(transaction.productID)
            } else {
                purchasedProductIDs.remove(transaction.productID)
            }
        }
    }

    public func restore() async throws {
        try await AppStore.sync()
    }

    // MARK: Private methods

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await _ in Transaction.updates {
                await updatePurchasedProducts()
            }
        }
    }
}
