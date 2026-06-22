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

## Testing

The project has two **Swift Testing** logic bundles (Xcode 16+; `import Testing`, `@Test`/`#expect`), run via the shared **`CurrencyConverterTests`** scheme, plus a separate **XCUITest** bundle (`import XCTest`) run via its own **`CurrencyConverterUITests`** scheme (see "UI Tests (XCUITest)" below):

- **CurrencyCoreTests** — framework-hosted logic tests for `CurrencyCore` (conversion math, `CoinMapping`, `Plist.load`, the property wrappers, `UserDefaultsMigrator`, `NetworkClient`/managers via a mock client + URLProtocol stub, and `CurrencyService` via mock workers/managers).
- **CurrencyConverterTests** — app-hosted (`TEST_HOST` = the app) tests for the workers (they read the bundled `*.plist` via `Bundle.main`, which only resolves inside the app), the `ConverterViewModel`/`CurrenciesListViewModel` derivation (black-box through the public API), the `PurchaseService` gate, and StoreKit-backed IAP tests (`PurchaseServiceStoreKitTests` + `Products.storekit`).
- **CurrencyConverterUITests** — black-box **XCUITest** target (`com.apple.product-type.bundle.ui-testing`, `TEST_TARGET_NAME` = the app) driving the real app on the simulator: launch/onboarding, the converter, the currencies list (segments, search, favoriting), and the subscription paywall.

> `PurchaseServiceStoreKitTests` runs against an in-process `SKTestSession` (`Products.storekit`). StoreKitTest is **broken on the iOS 26.3–26.5 simulator runtimes under headless `xcodebuild test`** — an Apple regression where the `.storekit`→`storekitd` config sync is IDE-only (`SKInternalErrorDomain Code=3` "Error saving configuration file" / `Code=12` "remote proxy … Sandbox"), so `Product.products(for:)` returns empty. The product-dependent tests therefore **self-skip** (early-return) when the StoreKit backend is unavailable, so the default `xcodebuild test` (which resolves to the newest, 26.5, runtime) stays green; `noEntitlementsMeansLocked` always runs. They genuinely run and pass on **iOS 26.0/26.1** (verified on 26.0 — full `loadProducts`/`purchase`→`hasUnlockedPro`/cross-instance-entitlement flow):
> ```bash
> # one-time: create an iOS 26.0 device (distinct name avoids clashing with the default 26.5 "iPhone 17")
> xcrun simctl create iPhone17-260 'iPhone 17' com.apple.CoreSimulator.SimRuntime.iOS-26-0
> xcodebuild test -scheme CurrencyConverterTests -project CurrencyConverter.xcodeproj \
>   -only-testing:CurrencyConverterTests/PurchaseServiceStoreKitTests \
>   -destination 'platform=iOS Simulator,name=iPhone17-260,OS=26.0'
> ```
> (the Xcode GUI test runner also works). The first `purchase()` is slow (~storekitd cold-start). The non-StoreKit `PurchaseServiceTests` (locked-by-default + `PurchaseError` cases) always run.

Run the full (logic) suite:
```bash
xcodebuild test -scheme CurrencyConverterTests -project CurrencyConverter.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Conventions worth keeping:
- Tests touching shared `AppGroup.userDefaults` (the `favoriteCurrencies`/`savedCurrencies` keys aren't injectable in the ViewModels / `CurrencyService`) must be **`.serialized`**. The two ViewModel suites are nested under one `.serialized` parent so they don't race each other; `URLProtocolStub`-based tests are serialized for the same reason (shared static state).
- ViewModel inputs (selected currency / amount / segment / search) can be set before or after `loadData()`: both the direct `recompute()`/`applyFilters()` inside `loadData` **and** the post-load Combine path now derive off committed/emitted values. (The Combine sinks pass the publisher's emitted values into `recompute(...)`/`applyFilters(...)` rather than re-reading the `@Published` properties, which would otherwise be stale-by-one because `@Published` fires in `willSet` — this was a real bug that showed the *previous* segment/search/base in the live UI; see the ViewModels section.)
- The logic test targets are registered in the hand-managed pbxproj (see below) — adding a new test file means wiring it into the right test target, same as any source file.

### UI Tests (XCUITest)

`CurrencyConverterUITests/` is a black-box XCUITest bundle. Run it via its own scheme (kept separate so the fast logic suite above isn't slowed by ~3.5 min of UI runs):
```bash
xcodebuild test -scheme CurrencyConverterUITests -project CurrencyConverter.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

It is made **deterministic** by an opt-in test mode in the app target (entirely inert in production — gated on a launch argument):
- **`CurrencyConverter/Support/UITestConfig.swift`** — when the app is launched with the `UITESTS` argument (`UITestLaunchArgument.activation`), `bootstrapIfNeeded()` (called first thing in `CurrencyConverterApp.init`) skips/forces onboarding, seeds a fixed favorites set into the app group, clears the persisted snapshot, hides the ad banner, and collapses onboarding animations to instant + skips the ATT prompt. Adding `UITESTS_ONBOARDING` shows the onboarding flow instead of skipping it.
- **`UITestStubCurrencyService.swift`** — a network-free `CurrencyServiceProtocol` returning `UITestFixtures.currencies` (4 fiat: USD/EUR/GBP/JPY, 3 crypto: BTC/ETH/SOL). `CurrencyConverterApp` injects it instead of the real `CurrencyService` when `UITestConfig.isActive`.
- **`AccessibilityIdentifiers.swift`** (`AXID` + `UITestLaunchArgument`) — stable identifiers, the **one source file compiled into both the app and the UI-test target** (it's Foundation-only; the UI-test bundle can't import the app module). Views set `.accessibilityIdentifier(AXID...)`; tests query the same constants.
- The base class **`UITestCase`** launches via `launchApp(onboarding:)` and offers `assertExists` / `assertEventuallyGone` / `tapWhenReady` helpers. List rows expose `identifier: list.row.<CODE>` and an `accessibilityValue` of `saved`/`unsaved`.
- Like the logic targets, `CurrencyConverterUITests` is hand-wired into the pbxproj — a **new UI test file must be added to the `CurrencyConverterUITests` target's sources** (the four pbxproj entries, or via Xcode). The target was created with the `xcodeproj` Ruby gem; the shared scheme lives at `xcshareddata/xcschemes/CurrencyConverterUITests.xcscheme`.

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
- `.crypto` - Cryptocurrencies (BTC, ETH, SOL, etc.)

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

- `ConverterViewModel` (`Screens/Converter`): Main conversion screen. Holds an immutable favorites snapshot and derives the displayed list via a local `recompute(...)` (rate conversion + amount) — changing the base currency or amount does **not** refetch; only the on-appear `loadData()` hits the service
- `CurrenciesListViewModel` (`Screens/List`): Currency list management, integrates with `PurchaseService` for pro features. Holds an immutable source list and derives the displayed list via `applyFilters(...)` (search + segment) without mutating the source; favorites are tracked in the published `favoriteCodes` set

> Both VMs subscribe to their `@Published` inputs via `CombineLatest(...).sink`. The sink passes the **emitted** values into `recompute(...)`/`applyFilters(...)`; it must **not** re-read `self.<published>` inside the closure — `@Published` fires its publisher in `willSet`, so a re-read sees the *previous* value and the UI renders one change behind (wrong segment/search/base). The `loadData` path calls these methods with no arguments, so they fall back to the committed published values.

> Both VMs (and `PurchaseService`) are owned by `CurrencyConverterApp` as **`@StateObject`** (constructed once in `App.init`, injected via `.environmentObject`). Do **not** construct them inline in `body` (e.g. `.environmentObject(ConverterViewModel(...))`): `body` re-evaluates whenever an observed object changes (notably when `purchaseService`'s `.task` finishes), which would rebuild a fresh, empty VM and blank out the already-loaded converter/list while `.task`'s `loadData` no longer re-runs.

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
