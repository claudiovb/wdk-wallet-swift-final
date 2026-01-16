import SwiftUI
import WDKClient

@main
struct WDKWalletDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Run test workflow
                    Task {
                        await testWDKWorkflow()
                    }
                }
        }
    }
    
    /// Test WDK workflow demonstrating key operations
    private func testWDKWorkflow() async {
        // Use a well-known test mnemonic (never use this in production!)
        let seedPhrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        
        // Create WDK client (worklet and IPC are handled internally)
        let wdkClient = WDKClient()
        
        do {
            // Step 1: Start worklet
            print("📝 Step 1: Starting worklet...")
            try await wdkClient.workletStart()
            print("✅ Worklet started!\n")
            
            // Step 2: Convert mnemonic to encrypted seed
            print("🔐 Step 2: Converting mnemonic to encrypted seed...")
            let seedResult = try await wdkClient.getSeedAndEntropyFromMnemonic(mnemonic: seedPhrase)
            print("✅ Success!")
            print("Encryption Key: \(seedResult.encryptionKey)")
            print("Encrypted Seed: \(seedResult.encryptedSeedBuffer)")
            
            // Step 3: Initialize WDK with Ethereum configuration
            print("\n🔧 Step 3: Initializing WDK with Ethereum configuration...")
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
                encryptionKey: seedResult.encryptionKey,
                encryptedSeed: seedResult.encryptedSeedBuffer,
                config: config
            )
            print("✅ WDK initialized!")
            
            // Step 4: Get Ethereum address
            print("\n📬 Step 4: Getting Ethereum address...")
            let address = try await wdkClient.getAddress(network: "ethereum", accountIndex: 0)
            print("✅ Address: \(address)")
            
            // Step 5: Demonstrate dynamic wallet registration
            print("\n🔄 Step 5: Dynamically registering Solana wallet...")
            let solanaConfig = """
            {
                "networks": {
                    "solana": {
                        "cluster": "mainnet-beta",
                        "rpcUrl": "https://api.mainnet-beta.solana.com"
                    }
                }
            }
            """
            let registered = try await wdkClient.registerWallet(config: solanaConfig)
            print("✅ Registered networks: \(registered)")
            
            // Step 6: Get Solana address
            print("\n📬 Step 6: Getting Solana address...")
            let solAddress = try await wdkClient.getAddress(network: "solana", accountIndex: 0)
            print("✅ Solana Address: \(solAddress)")
            
            // Step 7: Cleanup
            print("\n🧹 Step 7: Cleaning up...")
            try await wdkClient.dispose()
            print("✅ WDK disposed successfully!")
            
            print("\n✨ All tests passed! ✨\n")
            
        } catch let error as WDKError {
            switch error {
            case .rpcError(let code, let message):
                print("❌ RPC Error [\(code)]: \(message)")
            case .ipcError(let message):
                print("❌ IPC Error: \(message)")
            case .invalidResponse(let message):
                print("❌ Invalid Response: \(message)")
            case .encodingError(let message):
                print("❌ Encoding Error: \(message)")
            }
        } catch {
            print("❌ Unexpected Error: \(error)")
        }
    }
}
