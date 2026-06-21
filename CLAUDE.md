# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

Build the project:
```bash
xcodebuild -scheme CurrencyConverter -project CurrencyConverter.xcodeproj build
```

Clean build:
```bash
xcodebuild -scheme CurrencyConverter -project CurrencyConverter.xcodeproj clean build
```

List all targets and schemes:
```bash
xcodebuild -list -project CurrencyConverter.xcodeproj
```

**There are no test targets** in this project (no XCTest bundles). `xcodebuild test` will not run anything — don't suggest it as a verification step. Verify changes with a build.

## Adding New Source Files (Important)

This project uses a hand-managed `.pbxproj` — new `.swift`/asset files are **not** picked up automatically. Creating a file on disk and building will silently exclude it. To register a file you must add all four of its `project.pbxproj` entries: a `PBXBuildFile`, a `PBXFileReference`, the owning group's `children` entry, and the target's `PBXSourcesBuildPhase`. Easiest is to add the file through Xcode's UI (which does this for you); if editing the pbxproj by hand, copy an existing sibling file in the same group/target as a template and double-check it lands in the intended target. Always confirm the new file actually compiles into the right target with a build afterward.

> The repo previously carried a pile of root-level helper scripts for this (`add_files_to_xcode.{py,rb}`, `fix_file_paths.rb`, `absolute_paths_fix.rb`, `final_fix*.rb`, `remove_duplicates.rb`, `add_design_system_files.sh`). They targeted a since-reverted `DesignSystem/` tree and have been deleted — don't go looking for them.

`fix_google_frameworks.sh` is the one script that remains, and it is **not** a one-off: it is wired into the CurrencyConverter target as the "Fix Google Frameworks Info.plist" run-script build phase. It synthesizes the missing `Info.plist` files that the SPM-distributed `GoogleMobileAds` / `UserMessagingPlatform` frameworks ship without. Leave it in place — removing it (or its build phase) breaks the build.

## Project Structure

This is an iOS currency converter app built with SwiftUI that supports fiat currencies and cryptocurrencies.

> Note: the core services directory is literally spelled `CurrencyCore/Serivces/` (a typo baked into the paths). Don't "correct" it — file paths and the pbxproj depend on it.

### Targets

- **CurrencyConverter**: Main iOS app target
- **CurrencyCore**: Core framework containing business logic, models, and currency services
- **Subscriptions**: In-app purchase module
- **WidgetIntent**: Siri intents for widget functionality
- **ListWidgetExtension**: iOS widget extension

### Architecture

**Two-Tier Currency System:**

The app handles two types of currencies (`CurrencyType` enum):
- `.fiat` - Traditional currencies (USD, EUR, etc.)
- `.crypto` - Cryptocurrencies (BTC, ETH, TON, etc.)

**CurrencyService (Actor):**

Located in `CurrencyCore/CurrencyService.swift`, this is the central service that:
- Fetches exchange rates from two sources **concurrently** (`async let`) via a network-manager + worker pattern; the call fails atomically if either source throws
- Aggregates fiat and crypto currencies into a unified list (sorted by `code`)
- Fetches every rate against a single **canonical base (USD)**; callers re-express the list against a user-selected currency on the client via `Currency.converted(against:)` (exact, since all rates share the base). There is intentionally **no** per-call base parameter — the crypto source is always priced in USD, so a mixed base would give inconsistent cross-rates
- Caches the combined list in-memory with a **TTL** (`cacheTTL`, default 300s): a call within the window returns the cache, otherwise it refetches
- Manages currency persistence via the `@CodableUserDefault` wrapper (`savedCurrencies`)
- Runs the old→app-group `UserDefaults` migration once at `init` (see `UserDefaultsMigrator` below); `getSavedCurrencies()` is now just the persisted read

Each source is a **protocol + concrete pair**, injected into `CurrencyService.init` (defaults shown), so they can be swapped for tests/previews:

1. **Fiat**: `FiatNetworkManager` (concrete `FiatNetwork`) + `FiatCurrencyWorker` (concrete `FiatWorker`)
   - Source: **Frankfurter API** (`https://api.frankfurter.app`), response type `ExchangeRatesResponse`
   - `FiatWorker` enriches rates with country flags / metadata from `CurrenciesInfo.plist`
2. **Crypto**: `CryptoNetworkManager` (concrete `CoinGeckoNetworkManager`) + `CryptoCurrencyWorker` (concrete `CryptoWorker`)
   - Source: **CoinGecko API** (`https://api.coingecko.com`), response type `[String: CoinGeckoResponse]`
   - `CoinGeckoNetworkManager` maps app currency codes ↔ CoinGecko IDs via the canonical `CoinMapping` (single source of truth); `CryptoWorker` enriches with metadata from `CryptoInfo.plist`

Both concrete network managers fetch through a shared `NetworkClient` (`CurrencyCore/Serivces/NetworkClient.swift`, default `URLSessionNetworkClient`), which validates the HTTP status (throws on non-2xx) and decodes — replacing the duplicated `URLSession` + `JSONDecoder` boilerplate. Managers build requests with the protocol-extension convenience `get(baseURL:path:queryItems:as:)`, which assembles the URL via `URLComponents` (percent-encoding query values) and throws `.invalidURL` — so each manager is a single call with no `URL(string:)` boilerplate. Both workers load their `*.plist` metadata via the shared `Plist.load(resource:)` helper. Failures surface as `CurrencyError` cases (`.invalidURL`, `.invalidResponse`, `.httpStatus`, `.decodingFailed`, `.missingPlistFile`). The client is injectable via each manager's `init` for tests.

> Note: the project previously used the Dedust API. `CoinGeckoResponse` still lives in `DedustResponse.swift` (the filename is a historical artifact). New code should reference the CoinGecko names.

**Data Flow:**
```
CurrencyService.getCurrencies()                 // all rates vs. canonical USD base
  ├─(async let)─> FiatWorker.prepareCurrencies(FiatNetwork.getExchangeRates(currencyCode: "USD"))  -> [Currency] (.fiat)
  └─(async let)─> CryptoWorker.prepareCurrencies(CoinGeckoNetworkManager.getExchangeRates())        -> [Currency] (.crypto)
       └─> Combined, sorted by code, TTL-cached in-memory, and persisted to savedCurrencies

UI re-expresses the list against the selected currency client-side:
  [Currency].converted(against:amount:)         // ConverterViewModel + ListWidgetProvider
```

**UserDefaults App Group:**

Two property wrappers (in `CurrencyCore/PropertyWrappers/`) both default to the shared suite via `AppGroup.userDefaults` (suite `group.gmg.CurrencyConverter`, falling back to `.standard` if unavailable), enabling data sharing between the main app and widget extension. Pass `userDefaults: .standard` explicitly to read pre-migration (non-app-group) keys. The suite name, the UserDefaults keys, and the first-launch default favorites are centralized in `AppGroup`, `UserDefaultsKey`, and `CurrencyDefaults` (all in `UserDefault.swift`) — use these constants rather than string literals.
- `@UserDefault` (`UserDefault.swift`) — for values UserDefaults stores **natively** (primitives, `Data`, and `[String]` such as `favoriteCurrencies`). No JSON involved.
- `@CodableUserDefault` (`CodableUserDefault.swift`) — for `Codable` types stored as **JSON `Data`** (e.g. `[Currency]` under `savedCurrencies`), via `JSONEncoder`/`JSONDecoder`.

> Wire-format caution: `favoriteCurrencies` (key `UserDefaultsKey.favoriteCurrencies`) is a native `[String]` array — seeded on first launch in `ContentView` from `CurrencyDefaults.favoriteCodes` — while `savedCurrencies` is JSON `Data`. Keep each key on its matching wrapper — switching a key's representation would orphan existing users' stored data.

**Migration (`UserDefaultsMigrator`):**

`CurrencyCore/Migration/UserDefaultsMigrator.swift` copies pre-app-group keys (`savedCurrencies`, `favoriteCurrencies`) from `.standard` into the shared suite. It is **idempotent**: a key is copied only when the legacy store has a value AND the shared store does not (never clobbers newer shared data), then the legacy key is cleared. It runs once from `CurrencyService.init` and is injectable for tests.

**ViewModels:**

- `ConverterViewModel` (`Screens/Converter`): Main conversion screen. Holds an immutable favorites snapshot and derives the displayed list via a local `recompute()` (rate conversion + amount) — changing the base currency or amount does **not** refetch; only the on-appear `loadData()` hits the service
- `CurrenciesListViewModel` (`Screens/List`): Currency list management, integrates with `PurchaseService` for pro features. Holds an immutable source list and derives the displayed list via `applyFilters()` (search + segment) without mutating the source; favorites are tracked in the published `favoriteCodes` set

**In-App Purchases:**

`PurchaseService` (in `Subscriptions/PurchaseService.swift`):
- Manages StoreKit 2 subscriptions (StoreKit 2 only — the legacy `SKPaymentTransactionObserver` conformance was removed)
- Product IDs are **injected via `init(productsId:)`** rather than hardcoded; the app passes `["annual.ocean.plus"]` at call sites
- `purchase(_:)` throws `PurchaseError` (`.cancelled` for a user dismiss, `.unverified` for a failed signature check) rather than misusing a StoreKit verification error
- Tracks purchased products via `purchasedProductIDs`; `hasUnlockedPro` computed property gates pro features

## Dependencies

Swift Package Manager dependencies (resolved by Xcode on build):
- **Lottie**: Animations (onboarding)
- **SwiftFlags**: Country flag emojis for fiat currencies
- **CachedAsyncImage**: Image caching for crypto icons
- **Firebase**: Analytics / app measurement — requires `CurrencyConverter/GoogleService-Info.plist`
- **GoogleMobileAds**: Ad integration

## Key Data Models

**Currency** (`CurrencyCore/Models/Currency.swift`):
```swift
struct Currency: Identifiable, Codable {
    let name: String
    let imageSource: ImageSource  // .flag(String) or .image(URL)
    let code: String
    let rate: Double
    let type: CurrencyType
}
```

**ImageSource** — Enum supporting both flag emojis (fiat) and remote URLs (crypto).

**Plist<T>** (`CurrencyCore/Models/Plist.swift`) — generic `{ currencies: [T] }` wrapper used to decode `CurrenciesInfo.plist` / `CryptoInfo.plist`.
