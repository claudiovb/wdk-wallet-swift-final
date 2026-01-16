# WDK-Wallet-Demo

Example iOS application demonstrating how to use the WDKClient Swift package with the WDK worklet for multi-chain wallet operations.

## Features

- **Multi-Chain Support**: Demonstrates Ethereum and Solana wallet operations
- **Mnemonic Management**: Shows seed phrase handling with encryption
- **Dynamic Wallet Registration**: Demonstrates adding networks at runtime
- **BareKit Integration**: Uses BareKit worklet for JavaScript runtime
- **XcodeGen Project**: Uses XcodeGen for reproducible project generation

## Prerequisites

- macOS 14.0+
- Xcode 15.0+
- Node.js 18+ (for building worklet)
- npm or yarn
- XcodeGen (`brew install xcodegen`)

## Setup

### 1. Copy BareKit Framework

You need to copy the `BareKit.xcframework` to the `frameworks/` directory:

```bash
# From your BareKit build location
cp -r path/to/BareKit.xcframework WDK-Wallet-Demo/frameworks/
```

Alternatively, the framework will be downloaded via Swift Package Manager from the BareKit repository.

### 2. Install Worklet Dependencies

```bash
cd ../pear-wrk-wdk-jsonrpc
npm install
```

### 3. Build Worklet Bundle

```bash
cd ../pear-wrk-wdk-jsonrpc
npm run build:bundle
```

This creates `generated/wdk-worklet.mobile.bundle`.

### 4. Generate Xcode Project

```bash
cd WDK-Wallet-Demo
xcodegen generate
```

This creates `WDK-Wallet-Demo.xcodeproj` from `project.yml`.

### 5. Open in Xcode

```bash
open WDK-Wallet-Demo.xcodeproj
```

## Building

### Using Xcode

1. Open `WDK-Wallet-Demo.xcodeproj`
2. Select your target device or simulator
3. Press Cmd+B to build
4. Press Cmd+R to run

The pre-action script in the scheme will automatically:

- Build the worklet bundle if needed
- Copy it to the app bundle

### Using Command Line

```bash
xcodebuild -project WDK-Wallet-Demo.xcodeproj \
  -scheme WDK-Wallet-Demo \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Project Structure

```
WDK-Wallet-Demo/
├── project.yml                 # XcodeGen configuration
├── WDK-Wallet-Demo/
│   ├── App.swift              # App entry point with WDK workflow
│   ├── ContentView.swift      # Main UI view
│   ├── Info.plist             # App configuration
│   └── Assets.xcassets/       # App assets
├── frameworks/
│   └── BareKit.xcframework/   # BareKit framework (copy here)
├── wdk-worklet.mobile.bundle  # Compiled worklet (auto-generated)
└── README.md
```

## How It Works

### 1. Initialize WDKClient

```swift
import WDKClient

// Create WDK client (worklet and IPC are handled internally)
let wdkClient = WDKClient()

// Optional: Explicitly start the worklet (happens automatically on first use)
try await wdkClient.workletStart()
```

The `WDKClient` handles all worklet initialization and IPC communication internally. The worklet bundle (`wdk-worklet.mobile.bundle`) is automatically loaded and initialized on first use with a 500ms startup delay.

### 2. Seed Management

```swift
// Convert mnemonic to encrypted seed
let seedResult = try await wdkClient.getSeedAndEntropyFromMnemonic(mnemonic: mnemonic)

// Store these securely
let encryptionKey = seedResult.encryptionKey
let encryptedSeed = seedResult.encryptedSeedBuffer
```

### 3. WDK Initialization

```swift
let config = """
{
  "networks": {
    "ethereum": {
      "chainId": 1,
      "blockchain": "ethereum",
      "provider": "https://rpc.mevblocker.io/fast",
      "transferMaxFee": 100000
    }
  }
}
"""

try await wdkClient.initializeWDK(
    encryptionKey: encryptionKey,
    encryptedSeed: encryptedSeed,
    config: config
)
```

### 4. Account Operations

```swift
// Get address
let address = try await wdkClient.getAddress(network: "ethereum", accountIndex: 0)

// Get balance
let balance = try await wdkClient.getBalance(network: "ethereum", accountIndex: 0)
```

## Workflow Example

The demo app runs through a complete workflow:

1. ✅ Start worklet
2. ✅ Convert test mnemonic to encrypted seed
3. ✅ Initialize WDK with Ethereum configuration
4. ✅ Get Ethereum address (0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)
5. ✅ Dynamically register Solana wallet
6. ✅ Get Solana address
7. ✅ Cleanup and dispose

Check the Xcode console to see detailed logs from each step.

## Configuration

### Network Configuration

Edit the config in `App.swift` to add or modify networks:

```swift
let config = """
{
  "networks": {
    "ethereum": {
      "chainId": 1,
      "blockchain": "ethereum",
      "provider": "https://your-rpc-url.com",
      "transferMaxFee": 100000
    },
    "polygon": {
      "chainId": 137,
      "blockchain": "polygon",
      "provider": "https://polygon-rpc.com",
      "transferMaxFee": 100000
    }
  }
}
"""
```

### Supported Networks

- `ethereum` - Ethereum mainnet
- `sepolia` - Ethereum Sepolia testnet
- `polygon` - Polygon mainnet
- `arbitrum` - Arbitrum One
- `solana` - Solana mainnet/testnet/devnet
- `ethereum-erc4337` - Ethereum with account abstraction

## Customization

### Change Test Mnemonic

Edit the mnemonic in `App.swift`:

```swift
let seedPhrase = "your twelve or twenty four word phrase here"
```

**⚠️ Never use test mnemonics in production!**

### Add New Features

1. Create new view in `WDK-Wallet-Demo/`
2. Add to `Sources` in `project.yml`
3. Regenerate project: `xcodegen generate`

### Modify UI

Edit `ContentView.swift` to customize the user interface.

## Troubleshooting

### Worklet Bundle Not Found

**Error:** `Could not find bundle wdk-worklet.mobile`

**Solution:**

```bash
cd ../pear-wrk-wdk-jsonrpc
npm run build:bundle
cp generated/wdk-worklet.mobile.bundle ../WDK-Wallet-Demo/
```

### BareKit Framework Missing

**Error:** `Framework not found BareKit`

**Solution:**
Copy `BareKit.xcframework` to `frameworks/` directory or ensure Swift Package Manager dependency is resolved.

### Node Modules Not Found

**Error:** `npm: command not found` or `bare-pack: command not found`

**Solution:**

```bash
cd ../pear-wrk-wdk-jsonrpc
npm install
```

### Build Script Fails

If the pre-action script fails, you can manually build and copy:

```bash
cd ../pear-wrk-wdk-jsonrpc
npm run build:bundle
cp generated/wdk-worklet.mobile.bundle ../WDK-Wallet-Demo/
```

Then build from Xcode.

### XcodeGen Errors

**Error:** `Project spec not found`

**Solution:**
Ensure you're in the `WDK-Wallet-Demo` directory when running `xcodegen generate`.

## Development

### Rebuilding Worklet

During development, rebuild the worklet after changes:

```bash
cd ../pear-wrk-wdk-jsonrpc
npm run build:bundle
```

The pre-action script will copy the new bundle automatically on next build.

### Debugging

1. **Enable Debug Logs**: Check Xcode console for detailed output
2. **Worklet Logs**: JavaScript logs appear in Xcode console with `[INFO]` prefix
3. **Breakpoints**: Set breakpoints in Swift code as usual
4. **Network Inspector**: Use Charles Proxy or similar to inspect RPC calls

### Adding Dependencies

Edit `project.yml` and add to `dependencies`:

```yaml
dependencies:
  - package: YourPackage
```

Then regenerate: `xcodegen generate`

## Testing

The app includes a complete test workflow that runs automatically on launch:

1. Mnemonic -> Encrypted Seed conversion
2. WDK initialization with Ethereum
3. Address retrieval
4. Dynamic wallet registration (Solana)
5. Multi-network address retrieval
6. Cleanup

Check the console output to verify all steps pass.

## Production Considerations

Before deploying to production:

1. **Secure Storage**: Use Keychain for encryption keys and encrypted seeds
2. **Error Handling**: Implement proper error handling and user feedback
3. **Network Selection**: Let users choose networks (mainnet/testnet)
4. **Mnemonic Backup**: Implement secure mnemonic backup and recovery
5. **Transaction Signing**: Add user confirmation for all transactions
6. **Rate Limiting**: Implement rate limiting for RPC calls
7. **Logging**: Remove or secure all console logs in production builds

## Architecture

```
┌─────────────────────────────────┐
│      WDK-Wallet-Demo App        │
│                                 │
│  ┌──────────────────────────┐  │
│  │     ContentView          │  │
│  │   (SwiftUI Interface)    │  │
│  └──────────┬───────────────┘  │
│             │                   │
│  ┌──────────▼───────────────┐  │
│  │      WDKClient           │  │
│  │   (Swift Package)        │  │
│  └──────────┬───────────────┘  │
│             │ IPC              │
│  ┌──────────▼───────────────┐  │
│  │    Worklet (BareKit)     │  │
│  │  wdk-worklet.mobile      │  │
│  └──────────┬───────────────┘  │
└─────────────┼───────────────────┘
              │ JSON-RPC 2.0
    ┌─────────▼──────────┐
    │   WDK JavaScript   │
    │   Runtime Engine   │
    └────────────────────┘
```

## Resources

- [WDKClient Package](../WDKClient/)
- [pear-wrk-wdk-jsonrpc Worklet](../pear-wrk-wdk-jsonrpc/)
- [BareKit Documentation](https://github.com/holepunchto/bare-kit-swift)
- [XcodeGen Documentation](https://github.com/yonaskolb/XcodeGen)

## License

Apache-2.0

## Author

Tether
