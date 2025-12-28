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

## Project Structure

This is an iOS currency converter app built with SwiftUI that supports fiat currencies, cryptocurrencies, and TON blockchain jettons.

### Targets

- **CurrencyConverter**: Main iOS app target
- **CurrencyCore**: Core framework containing business logic, models, and currency services
- **Subscriptions**: In-app purchase module (annual.ocean.plus)
- **WidgetIntent**: Siri intents for widget functionality
- **ListWidgetExtension**: iOS widget extension

### Architecture

**Three-Tier Currency System:**

The app handles three types of currencies (`CurrencyType` enum):
- `.fiat` - Traditional currencies (USD, EUR, etc.)
- `.crypto` - Cryptocurrencies (BTC, ETH, TON, etc.)
- `.jetton` - TON blockchain tokens

**CurrencyService (Actor):**

Located in `CurrencyCore/CurrencyService.swift`, this is the central service that:
- Fetches exchange rates from three parallel sources via worker pattern
- Aggregates fiat, crypto, and jetton currencies into a unified list
- Manages currency persistence using `@UserDefault` property wrapper
- Implements migration from old UserDefaults to shared app group (`group.gmg.CurrencyConverter`)

The service uses three worker/network manager pairs:
1. **Fiat**: `FiatNetworkManager` + `FiatWorker` - Fetches fiat exchange rates, enriches with country flags from `CurrenciesInfo.plist`
2. **Crypto**: `CryptoNetworkManager` (Dedust API) + `CryptoWorker` - Fetches crypto prices, enriches with metadata from `CryptoInfo.plist`
3. **Jettons**: `JettonsNetworkManager` (Redoubt API) + `JettonsWorker` - Fetches TON jetton prices (requires TON price from crypto worker)

**Data Flow:**
```
CurrencyService.getCurrencies()
  ├─> FiatWorker.prepareCurrencies() -> [Currency] (.fiat)
  ├─> CryptoWorker.prepareCurrencies() -> [Currency] (.crypto)
  └─> JettonsWorker.prepareCurrencies(tonPrice) -> [Currency] (.jetton)
       └─> Combined, sorted, and cached
```

**UserDefaults App Group:**

The `@UserDefault` property wrapper (in `CurrencyCore/PropertyWrappers/UserDefault.swift`) uses shared UserDefaults:
- Suite name: `group.gmg.CurrencyConverter`
- Enables data sharing between main app and widget extension
- Handles special encoding/decoding for `[Currency]` arrays using JSONEncoder/JSONDecoder

**ViewModels:**

- `ConverterViewModel`: Main conversion screen, filters currencies by favorites, recalculates rates based on selected currency
- `CurrenciesListViewModel`: Currency list management, integrates with `PurchaseService` for pro features

**In-App Purchases:**

`PurchaseService` (in `Subscriptions/PurchaseService.swift`):
- Manages StoreKit 2 subscriptions
- Product ID: "annual.ocean.plus"
- Tracks purchased products via `purchasedProductIDs`
- `hasUnlockedPro` computed property for feature gating

## Dependencies

Key Swift Package Manager dependencies:
- **Lottie**: Animations (used in onboarding)
- **SwiftFlags**: Country flag emojis for fiat currencies
- **CachedAsyncImage**: Image caching for crypto/jetton icons
- **Firebase**: Analytics and app measurement
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

**ImageSource** - Enum supporting both flag emojis (fiat) and remote URLs (crypto/jettons)
