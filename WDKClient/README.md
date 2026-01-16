# WDKClient

Swift Package Manager package providing a clean, type-safe interface to the WDK (Web3 Development Kit) via JSON-RPC 2.0 communication with the JavaScript worklet.

## Features

- **Type-Safe API**: Strongly typed Swift interfaces for all WDK operations
- **Async/Await**: Modern Swift concurrency support
- **JSON-RPC 2.0**: Standard protocol for worklet communication
- **Multi-Chain**: Support for Ethereum, Polygon, Arbitrum, Sepolia, Solana
- **Secure**: Encrypted seed and mnemonic handling
- **Standalone**: Can be imported into any iOS/macOS project

## Requirements

- iOS 16.0+ / macOS 13.0+
- Swift 5.9+
- Xcode 15.0+
- BareKit framework (for IPC)

## Installation

### Swift Package Manager

Add WDKClient to your project via Swift Package Manager:

```swift
dependencies: [
    .package(path: "../WDKClient")
]
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/WDKClient.git", from: "1.0.0")
]
```

## Usage

### Basic Setup

```swift
import WDKClient

// Initialize WDKClient (worklet and IPC are handled internally)
let wdkClient = WDKClient()

// Optional: Explicitly start worklet (happens automatically on first use)
try await wdkClient.workletStart()

// Or just start using it directly - worklet initializes automatically
let address = try await wdkClient.getAddress(network: "ethereum")
```

**Note:** The WDK worklet bundle (`wdk-worklet.mobile.bundle`) must be included in your app's resources. See the demo app for reference.

**Automatic Initialization:** The worklet and IPC are initialized automatically on first use with a 500ms startup delay. Calling `workletStart()` explicitly is optional but recommended for better control.

### Advanced: Custom Bundle Name

If you need to use a different bundle name:

```swift
let wdkClient = WDKClient(bundleName: "my-custom-worklet")
```

### Creating a New Wallet

```swift
// Generate new mnemonic and encrypted seed
let entropyResult = try await wdkClient.generateEntropyAndEncrypt(wordCount: 12)

// Store these securely (e.g., Keychain)
let encryptionKey = entropyResult.encryptionKey
let encryptedSeed = entropyResult.encryptedSeedBuffer

// Later, retrieve mnemonic for backup
let mnemonic = try await wdkClient.getMnemonicFromEntropy(
    encryptedEntropy: entropyResult.encryptedEntropyBuffer,
    encryptionKey: encryptionKey
)
print("Backup your mnemonic: \(mnemonic)")
```

### Restoring from Mnemonic

```swift
let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"

let seedResult = try await wdkClient.getSeedAndEntropyFromMnemonic(mnemonic: mnemonic)

// Store encrypted seed securely
let encryptionKey = seedResult.encryptionKey
let encryptedSeed = seedResult.encryptedSeedBuffer
```

### Initializing WDK

```swift
// Configure networks
let config = """
{
  "networks": {
    "ethereum": {
      "chainId": 1,
      "blockchain": "ethereum",
      "provider": "https://rpc.mevblocker.io/fast",
      "transferMaxFee": 100000
    },
    "solana": {
      "cluster": "mainnet-beta",
      "rpcUrl": "https://api.mainnet-beta.solana.com"
    }
  }
}
"""

// Initialize WDK with encrypted seed
try await wdkClient.initializeWDK(
    encryptionKey: encryptionKey,
    encryptedSeed: encryptedSeed,
    config: config
)
```

### Getting Account Information

```swift
// Get Ethereum address
let ethAddress = try await wdkClient.getAddress(network: "ethereum", accountIndex: 0)
print("Ethereum address: \(ethAddress)")

// Get Solana address
let solAddress = try await wdkClient.getAddress(network: "solana", accountIndex: 0)
print("Solana address: \(solAddress)")

// Get balance
let balance = try await wdkClient.getBalance(network: "ethereum", accountIndex: 0)
print("Balance: \(balance)")
```

### Calling Custom Methods

For methods not wrapped by convenience functions:

```swift
// Call any method on account
let result = try await wdkClient.callMethod(
    methodName: "signTransaction",
    network: "ethereum",
    accountIndex: 0,
    args: "{\"to\":\"0x...\",\"value\":\"1000000000000000000\"}"
)

// Parse result
let resultData = result.data(using: .utf8)!
let transaction = try JSONDecoder().decode(Transaction.self, from: resultData)
```

### Dynamic Wallet Registration

Add networks after initialization:

```swift
let polygonConfig = """
{
  "networks": {
    "polygon": {
      "chainId": 137,
      "blockchain": "polygon",
      "provider": "https://polygon-rpc.com",
      "transferMaxFee": 100000
    }
  }
}
"""

let registered = try await wdkClient.registerWallet(config: polygonConfig)
print("Registered networks: \(registered)")
```

### Cleanup

```swift
// Dispose WDK instance when done
try await wdkClient.dispose()

// Terminate worklet
worklet.terminate()
```

## Error Handling

WDKClient provides structured error handling:

```swift
do {
    let address = try await wdkClient.getAddress(network: "ethereum")
    print("Address: \(address)")
} catch WDKError.rpcError(let code, let message) {
    print("RPC Error [\(code)]: \(message)")
} catch WDKError.ipcError(let message) {
    print("IPC Error: \(message)")
} catch WDKError.invalidResponse(let message) {
    print("Invalid Response: \(message)")
} catch WDKError.encodingError(let message) {
    print("Encoding Error: \(message)")
} catch {
    print("Unexpected error: \(error)")
}
```

## API Reference

### WDKClient

Main client class for interacting with WDK worklet.

#### Methods

##### Worklet Management

- `workletStart()` - Start and verify worklet is ready

##### Mnemonic & Seed Management

- `generateEntropyAndEncrypt(wordCount:)` - Generate new mnemonic and encrypted seed
- `getMnemonicFromEntropy(encryptedEntropy:encryptionKey:)` - Retrieve mnemonic from encrypted entropy
- `getSeedAndEntropyFromMnemonic(mnemonic:)` - Convert mnemonic to encrypted seed

##### WDK Initialization

- `initializeWDK(encryptionKey:encryptedSeed:config:)` - Initialize WDK with network configs

##### Account Operations

- `getAddress(network:accountIndex:)` - Get account address
- `getBalance(network:accountIndex:)` - Get account balance
- `callMethod(methodName:network:accountIndex:args:options:)` - Call any account method

##### Dynamic Configuration

- `registerWallet(config:)` - Register additional wallets
- `registerProtocol(config:)` - Register protocol support

##### Cleanup

- `dispose()` - Dispose WDK instance and free resources

### Types

#### EntropyResult

Result from `generateEntropyAndEncrypt`:

- `encryptionKey: String` - Base64 encryption key
- `encryptedSeedBuffer: String` - Base64 encrypted seed
- `encryptedEntropyBuffer: String` - Base64 encrypted entropy

#### SeedAndEntropyResult

Result from `getSeedAndEntropyFromMnemonic`:

- `encryptionKey: String` - Base64 encryption key
- `encryptedSeedBuffer: String` - Base64 encrypted seed
- `encryptedEntropyBuffer: String` - Base64 encrypted entropy

#### WDKConfig

Configuration structure for WDK initialization:

- `networks: [String: NetworkConfig]` - Network configurations
- `protocols: [String: ProtocolConfig]?` - Optional protocol configurations

### Errors

#### WDKError

- `ipcError(String)` - IPC communication error
- `rpcError(code: String, message: String)` - RPC protocol error
- `invalidResponse(String)` - Invalid response format
- `encodingError(String)` - JSON encoding/decoding error

## Best Practices

### Security

1. **Store encryption keys securely**: Use iOS Keychain or macOS Keychain
2. **Never log sensitive data**: Avoid logging mnemonics, seeds, or private keys
3. **Zero sensitive memory**: Worklet automatically zeros sensitive buffers
4. **Validate inputs**: Client validates all parameters before sending to worklet

### Error Handling

1. **Always handle errors**: Wrap WDK calls in do-catch blocks
2. **Check error codes**: Different error codes indicate different failure modes
3. **Retry on network errors**: Some operations may fail due to network issues

### Resource Management

1. **Dispose when done**: Call `dispose()` to free WDK resources
2. **One instance**: Only initialize WDK once per session
3. **Terminate worklet**: Stop worklet when app closes

## Architecture

```
┌─────────────────┐
│   iOS App       │
│                 │
│  ┌───────────┐  │
│  │WDKClient  │  │
│  └─────┬─────┘  │
│        │ IPC    │
│  ┌─────▼─────┐  │
│  │  Worklet  │  │
│  │ (BareKit) │  │
│  └───────────┘  │
└─────────────────┘
        │
        │ JSON-RPC 2.0
        ▼
  ┌─────────────┐
  │  WDK Core   │
  │  (JavaScript│
  │   Runtime)  │
  └─────────────┘
```

## Examples

See the [WDK-Wallet-Demo](../WDK-Wallet-Demo) app for complete examples.

## License

Apache-2.0

## Author

Tether
