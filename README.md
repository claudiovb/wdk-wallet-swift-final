# WDK Swift Bridge

Simplified implementation of the WDK (Web3 Development Kit) for iOS with Swift Package Manager support, JSON-RPC 2.0 protocol, and XcodeGen project generation.

## 🎯 Overview

This repository provides a clean, documented codebase for integrating WDK multi-chain wallet functionality into iOS applications. It includes:

- **Simplified JavaScript Worklet**: Pure JSON-RPC 2.0 (no HRPC/code generation complexity)
- **Swift Package Manager Package**: Standalone, importable WDKClient library
- **Demo iOS Application**: Complete example with XcodeGen configuration
- **Multi-Chain Support**: Ethereum, Polygon, Arbitrum, Sepolia, Solana
- **Account Abstraction**: ERC-4337 support for EVM chains
-

## 📁 Repository Structure

```
wdk-wallet-swift-final/
├── pear-wrk-wdk-jsonrpc/       # Simplified JS worklet (no HRPC)
│   ├── src/
│   │   ├── wdk-worklet.js      # Main entry point
│   │   ├── rpc-handlers.js     # JSON-RPC handlers
│   │   ├── utils/              # Utilities (crypto, validation, logger)
│   │   └── exceptions/         # Error handling
│   ├── package.json            # Dependencies & scripts
│   └── README.md
│
├── WDKClient/                  # Swift Package Manager package
│   ├── Package.swift           # SPM manifest
│   ├── Sources/WDKClient/
│   │   ├── WDKClient.swift     # Main client
│   │   ├── WDKTypes.swift      # Type definitions
│   │   └── WDKError.swift      # Error types
│   └── README.md
│
├── WDK-Wallet-Demo/            # Example iOS app
│   ├── project.yml             # XcodeGen configuration
│   ├── WDK-Wallet-Demo/
│   │   ├── App.swift           # App entry point
│   │   ├── ContentView.swift   # Main UI
│   │   └── Assets.xcassets/    # App assets
│   ├── frameworks/             # BareKit.xcframework
│   └── README.md
│
├── .gitignore                  # Root gitignore
└── README.md                   # This file
```

## 🚀 Quick Start

### Prerequisites

- **macOS** 14.0+
- **Xcode** 15.0+
- **Node.js** 18+ and npm
- **XcodeGen**: `brew install xcodegen`

### 1. Clone Repository

```bash
git clone <repository-url>
cd wdk-wallet-swift-final
```

### 2. Build Worklet

```bash
cd pear-wrk-wdk-jsonrpc
npm install
npm run build:bundle
```

### 3. Copy BareKit Framework

```bash
# Copy BareKit.xcframework to demo app
cp -r /path/to/BareKit.xcframework WDK-Wallet-Demo/frameworks/
```

### 4. Generate & Run Demo

```bash
cd ../WDK-Wallet-Demo
xcodegen generate
open WDK-Wallet-Demo.xcodeproj
```

Press Cmd+R to run on simulator.

## 📦 Components

### 1. pear-wrk-wdk-jsonrpc

Simplified JavaScript worklet with JSON-RPC 2.0 interface.

**Key Features:**

- No HRPC, no code generation - just pure JSON-RPC
- Direct WDK module imports
- AES-256-GCM encryption for sensitive data
- Comprehensive error handling

**Build Commands:**

```bash
npm run build:bundle      # Build iOS bundle
npm run build:addons      # Build bare addons
npm run build:all         # Build everything
```

**Supported Networks:**

- `ethereum` - Ethereum mainnet (EVM)
- `polygon` - Polygon network (EVM)
- `arbitrum` - Arbitrum One (EVM)
- `sepolia` - Ethereum Sepolia testnet (EVM)
- `ethereum-erc4337` - Ethereum with account abstraction
- `solana` - Solana network

[Full Documentation →](./pear-wrk-wdk-jsonrpc/README.md)

### 2. WDKClient

Swift Package Manager package providing type-safe WDK interface.

**Key Features:**

- Modern async/await API
- Strongly typed Swift interfaces
- Comprehensive error handling
- Platform independent (iOS 16+, macOS 13+)

**Installation:**

```swift
dependencies: [
    .package(path: "../WDKClient")
]
```

**Basic Usage:**

```swift
import BareKit
import WDKClient

let worklet = Worklet()
worklet.start(name: "wdk-worklet.mobile", ofType: "bundle")

let ipc = IPC(worklet: worklet)
let wdkClient = WDKClient(ipc: ipc)

// Convert mnemonic to encrypted seed
let seedResult = try await wdkClient.getSeedAndEntropyFromMnemonic(
    mnemonic: "your mnemonic here"
)

// Initialize WDK
try await wdkClient.initializeWDK(
    encryptionKey: seedResult.encryptionKey,
    encryptedSeed: seedResult.encryptedSeedBuffer,
    config: configJSON
)

// Get address
let address = try await wdkClient.getAddress(network: "ethereum")
```

[Full Documentation →](./WDKClient/README.md)

### 3. WDK-Wallet-Demo

Example iOS application demonstrating complete WDK integration.

**Features:**

- Complete wallet workflow example
- Multi-chain address generation
- Dynamic wallet registration
- Clean SwiftUI interface
- Comprehensive logging

**Test Workflow:**

1. ✅ Start worklet
2. ✅ Convert mnemonic to encrypted seed
3. ✅ Initialize WDK with Ethereum
4. ✅ Get Ethereum address
5. ✅ Register Solana wallet dynamically
6. ✅ Get Solana address
7. ✅ Cleanup and dispose

[Full Documentation →](./WDK-Wallet-Demo/README.md)

## 🔒 Security

### Encryption

All sensitive data (seeds, mnemonics) are encrypted using AES-256-GCM:

- 256-bit encryption keys generated with cryptographically secure RNG
- Galois/Counter Mode (GCM) for authenticated encryption
- Memory zeroing after use (where possible in JavaScript)

### Storage

**DO:**

- Store encryption keys in iOS Keychain
- Store encrypted seeds securely
- Use biometric authentication for sensitive operations

**DON'T:**

- Never log sensitive data in production
- Never store unencrypted seeds or mnemonics
- Never use test mnemonics in production

## 🧪 Testing

### Run Worklet Tests

```bash
cd pear-wrk-wdk-jsonrpc
npm test
```

### Run Demo App

The demo app includes a comprehensive test workflow that runs automatically on launch. Check the Xcode console for detailed output.

## 🛠️ Development

### Worklet Development

1. Make changes to JavaScript files in `pear-wrk-wdk-jsonrpc/src/`
2. Rebuild: `npm run build:bundle`
3. Bundle is auto-copied to demo app on next Xcode build

### Swift Package Development

1. Make changes to Swift files in `WDKClient/Sources/WDKClient/`
2. Package is auto-updated in demo app (local dependency)
3. Test changes by running demo app

### Demo App Development

1. Make changes to `WDK-Wallet-Demo/WDK-Wallet-Demo/`
2. If modifying project structure, update `project.yml`
3. Regenerate: `xcodegen generate`

## 📝 JSON-RPC Methods

### Mnemonic & Seed

- `generateEntropyAndEncrypt` - Generate new mnemonic
- `getMnemonicFromEntropy` - Decrypt mnemonic
- `getSeedAndEntropyFromMnemonic` - Convert mnemonic to seed

### Initialization

- `workletStart` - Start worklet
- `initializeWDK` - Initialize WDK with config

### Account Operations

- `callMethod` - Call any WDK account method
- `getAddress` (convenience) - Get account address
- `getBalance` (convenience) - Get account balance

### Dynamic Configuration

- `registerWallet` - Add networks at runtime
- `registerProtocol` - Add protocol support

### Cleanup

- `dispose` - Dispose WDK instance

## 🌍 Supported Networks

| Network  | Type                | Chain ID | Status |
| -------- | ------------------- | -------- | ------ |
| Ethereum | EVM                 | 1        | ✅     |
| Sepolia  | EVM                 | 11155111 | ✅     |
| Polygon  | EVM                 | 137      | ✅     |
| Arbitrum | EVM                 | 42161    | ✅     |
| Solana   | Non-EVM             | -        | ✅     |
| ERC-4337 | Account Abstraction | -        | ✅     |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

Apache-2.0

## 👥 Authors

Tether

## 🔗 Resources

- [WDK Core Documentation](https://github.com/tetherto/wdk)
- [BareKit Documentation](https://github.com/holepunchto/bare-kit-swift)
- [XcodeGen Documentation](https://github.com/yonaskolb/XcodeGen)
- [Swift Package Manager](https://swift.org/package-manager/)

## 💡 Key Simplifications

This implementation differs from complex alternatives by:

1. **No HRPC**: Pure JSON-RPC 2.0 only
2. **No Code Generation**: Direct module imports
3. **No Schema Files**: Hardcoded wallet managers
4. **Minimal Dependencies**: Only essential packages
5. **Clear Separation**: Worklet, package, and demo are independent

These simplifications make the codebase easier to understand, maintain, and extend.

## 🚦 Status

- ✅ Worklet: Production ready
- ✅ WDKClient: Production ready
- ✅ Demo App: Example/testing only
- 📚 Documentation: Complete

## 📞 Support

For issues, questions, or contributions:

- Open an issue on GitHub
- Check documentation in component READMEs
- Review demo app for examples

---
