//
//  CurrencySnapshotStore.swift
//  CurrencyCore
//
//  Persistence for the last-known currency snapshot (`getSavedCurrencies`).
//

import Foundation

/// Reads/writes the persisted currency snapshot. Injected into `CurrencyService`
/// so tests can swap in an in-memory double instead of touching shared storage.
public protocol CurrencySnapshotStore {
    func load() -> [Currency]
    func save(_ currencies: [Currency])
}

/// Stores the snapshot as a JSON file in the shared app-group container.
///
/// This replaces keeping the list in UserDefaults: the list grew from a couple
/// dozen coins to ~1000, and UserDefaults is memory-mapped into every process
/// that opens the suite (including the widget/intent extensions) and is not
/// meant for blobs that size. A one-time fallback reads the old UserDefaults key
/// for existing installs; the next `save` writes the file and clears the key.
public struct FileCurrencySnapshotStore: CurrencySnapshotStore {
    private let fileURL: URL?
    private let legacyDefaults: UserDefaults
    private let legacyKey: String

    public init(
        appGroupID: String = AppGroup.suiteName,
        fileName: String = "savedCurrencies.json",
        legacyDefaults: UserDefaults = AppGroup.userDefaults,
        legacyKey: String = UserDefaultsKey.savedCurrencies
    ) {
        self.fileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
        self.legacyDefaults = legacyDefaults
        self.legacyKey = legacyKey
    }

    public func load() -> [Currency] {
        if let fileURL,
           let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([Currency].self, from: data) {
            return decoded
        }
        // One-time fallback: installs that still hold the snapshot under the old
        // UserDefaults key (or that the migrator just copied into the shared
        // suite). `save` moves it to the file and clears the key below.
        if let data = legacyDefaults.data(forKey: legacyKey),
           let decoded = try? JSONDecoder().decode([Currency].self, from: data) {
            return decoded
        }
        return []
    }

    public func save(_ currencies: [Currency]) {
        guard let fileURL, let data = try? JSONEncoder().encode(currencies) else { return }
        try? data.write(to: fileURL, options: .atomic)
        // Stop the old blob from bloating the shared suite once it lives in the file.
        if legacyDefaults.object(forKey: legacyKey) != nil {
            legacyDefaults.removeObject(forKey: legacyKey)
        }
    }
}
