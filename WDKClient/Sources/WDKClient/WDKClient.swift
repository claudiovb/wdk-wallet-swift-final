import Foundation
import BareKit

/// Swift client for WDK operations via JSON-RPC 2.0
/// Handles worklet lifecycle and IPC communication internally
public class WDKClient {
    private let worklet: Worklet
    private var ipc: IPC?
    private var requestId: Int = 0
    private let requestIdQueue = DispatchQueue(label: "com.wdk.requestId")
    private var isWorkletStarted = false
    private let bundleName: String
    
    /// Initialize WDKClient
    /// - Parameter bundleName: Name of the worklet bundle (default: "wdk-worklet.mobile")
    public init(bundleName: String = "wdk-worklet.mobile") {
        self.worklet = Worklet()
        self.bundleName = bundleName
    }
    
    deinit {
        // Cleanup worklet on deinitialization
        worklet.terminate()
    }
    
    /// Ensures the worklet and IPC are initialized
    private func ensureWorkletStarted() async throws {
        guard !isWorkletStarted else { return }
        
        // Start the worklet
        worklet.start(name: bundleName, ofType: "bundle")
        
        // Give worklet time to initialize (500ms)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Create IPC after worklet is ready
        self.ipc = IPC(worklet: worklet)
        
        isWorkletStarted = true
    }
    
    // MARK: - Private Helper Methods
    
    private func nextRequestId() -> Int {
        requestIdQueue.sync {
            requestId += 1
            return requestId
        }
    }
    
    private func call(method: String, params: [String: Any]) async throws -> [String: Any] {
        // Ensure worklet and IPC are ready
        try await ensureWorkletStarted()
        
        guard let ipc = self.ipc else {
            throw WDKError.ipcError("IPC not initialized")
        }
        
        let id = nextRequestId()
        
        let request: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id,
            "method": method,
            "params": params
        ]
        
        let requestData = try JSONSerialization.data(withJSONObject: request, options: [])
        
        // Send request
        try await ipc.write(data: requestData)
        
        // Read response
        guard let responseData = try await ipc.read() else {
            throw WDKError.ipcError("No response from worklet")
        }
        
        let obj = try JSONSerialization.jsonObject(with: responseData, options: [])
        guard let response = obj as? [String: Any] else {
            throw WDKError.invalidResponse("Invalid JSON response")
        }
        
        // Check for JSON-RPC error
        if let error = response["error"] as? [String: Any] {
            let errorMessage = error["message"] as? String ?? "Unknown error"
            let errorCode = error["code"] as? String ?? "UNKNOWN"
            throw WDKError.rpcError(code: errorCode, message: errorMessage)
        }
        
        // Return the result
        guard let result = response["result"] as? [String: Any] else {
            throw WDKError.invalidResponse("Missing result in response")
        }
        
        return result
    }
    
    // MARK: - Public API Methods
    
    /// Start the worklet
    /// Note: This is called automatically on first use, but can be called explicitly
    /// to ensure the worklet is initialized before other operations.
    public func workletStart() async throws {
        _ = try await call(method: "workletStart", params: [:])
    }
    
    /// Generate entropy and encrypt it (for new wallet creation)
    /// - Parameter wordCount: Number of words for mnemonic (12 or 24)
    /// - Returns: Encrypted entropy result
    public func generateEntropyAndEncrypt(wordCount: Int) async throws -> EntropyResult {
        let result = try await call(method: "generateEntropyAndEncrypt", params: [
            "wordCount": wordCount
        ])
        
        guard let encryptionKey = result["encryptionKey"] as? String,
              let encryptedSeedBuffer = result["encryptedSeedBuffer"] as? String,
              let encryptedEntropyBuffer = result["encryptedEntropyBuffer"] as? String else {
            throw WDKError.invalidResponse("Invalid generateEntropyAndEncrypt response")
        }
        
        return EntropyResult(
            encryptionKey: encryptionKey,
            encryptedSeedBuffer: encryptedSeedBuffer,
            encryptedEntropyBuffer: encryptedEntropyBuffer
        )
    }
    
    /// Get mnemonic from encrypted entropy
    /// - Parameters:
    ///   - encryptedEntropy: Base64-encoded encrypted entropy
    ///   - encryptionKey: Base64-encoded encryption key
    /// - Returns: Mnemonic phrase
    public func getMnemonicFromEntropy(encryptedEntropy: String, encryptionKey: String) async throws -> String {
        let result = try await call(method: "getMnemonicFromEntropy", params: [
            "encryptedEntropy": encryptedEntropy,
            "encryptionKey": encryptionKey
        ])
        
        guard let mnemonic = result["mnemonic"] as? String else {
            throw WDKError.invalidResponse("Invalid getMnemonicFromEntropy response")
        }
        
        return mnemonic
    }
    
    /// Convert mnemonic phrase to encrypted seed and entropy
    /// - Parameter mnemonic: BIP39 mnemonic phrase
    /// - Returns: Encrypted seed and entropy
    public func getSeedAndEntropyFromMnemonic(mnemonic: String) async throws -> SeedAndEntropyResult {
        let result = try await call(method: "getSeedAndEntropyFromMnemonic", params: [
            "mnemonic": mnemonic
        ])
        
        guard let encryptionKey = result["encryptionKey"] as? String,
              let encryptedSeedBuffer = result["encryptedSeedBuffer"] as? String,
              let encryptedEntropyBuffer = result["encryptedEntropyBuffer"] as? String else {
            throw WDKError.invalidResponse("Invalid getSeedAndEntropyFromMnemonic response")
        }
        
        return SeedAndEntropyResult(
            encryptionKey: encryptionKey,
            encryptedSeedBuffer: encryptedSeedBuffer,
            encryptedEntropyBuffer: encryptedEntropyBuffer
        )
    }
    
    /// Initialize WDK with encrypted seed
    /// - Parameters:
    ///   - encryptionKey: Base64-encoded encryption key
    ///   - encryptedSeed: Base64-encoded encrypted seed
    ///   - config: WDK configuration JSON string
    public func initializeWDK(encryptionKey: String, encryptedSeed: String, config: String) async throws {
        _ = try await call(method: "initializeWDK", params: [
            "encryptionKey": encryptionKey,
            "encryptedSeed": encryptedSeed,
            "config": config
        ])
    }
    
    /// Call any method on a WDK account
    /// - Parameters:
    ///   - methodName: The method name to call (e.g., "getAddress", "getBalance")
    ///   - network: Network name (e.g., "ethereum", "polygon")
    ///   - accountIndex: Account index (default: 0)
    ///   - args: Optional arguments as JSON string
    ///   - options: Optional options as JSON string
    /// - Returns: Result as Any (can be String, Number, Array, Dictionary, etc.)
    public func callMethod(
        methodName: String,
        network: String,
        accountIndex: Int = 0,
        args: String? = nil,
        options: String? = nil
    ) async throws -> Any {
        var params: [String: Any] = [
            "methodName": methodName,
            "network": network,
            "accountIndex": accountIndex
        ]
        
        if let args = args {
            params["args"] = args
        }
        
        if let options = options {
            params["options"] = options
        }
        
        let result = try await call(method: "callMethod", params: params)
        
        guard let methodResult = result["result"] else {
            throw WDKError.invalidResponse("Invalid callMethod response")
        }
        
        return methodResult
    }
    
    /// Register additional wallet(s) to an already initialized WDK instance
    /// - Parameter config: Wallet configuration JSON string
    public func registerWallet(config: String) async throws -> [String] {
        let result = try await call(method: "registerWallet", params: [
            "config": config
        ])
        
        guard let blockchainsString = result["blockchains"] as? String else {
            throw WDKError.invalidResponse("Invalid registerWallet response")
        }
        
        // Parse the blockchains JSON array
        guard let data = blockchainsString.data(using: .utf8),
              let blockchains = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            throw WDKError.invalidResponse("Invalid blockchains format")
        }
        
        return blockchains
    }
    
    /// Register protocol to an already initialized WDK instance
    /// - Parameter config: Protocol configuration JSON string
    public func registerProtocol(config: String) async throws {
        _ = try await call(method: "registerProtocol", params: [
            "config": config
        ])
    }
    
    /// Dispose the WDK instance and clean up resources
    public func dispose() async throws {
        _ = try await call(method: "dispose", params: [:])
    }
    
    // MARK: - Convenience Methods
    
    /// Get account address
    /// - Parameters:
    ///   - network: Network name
    ///   - accountIndex: Account index
    /// - Returns: Account address
    public func getAddress(network: String, accountIndex: Int = 0) async throws -> String {
        let result = try await callMethod(
            methodName: "getAddress",
            network: network,
            accountIndex: accountIndex
        )
        
        guard let address = result as? String else {
            throw WDKError.invalidResponse("Invalid address format")
        }
        
        return address
    }
    
    /// Get account balance
    /// - Parameters:
    ///   - network: Network name
    ///   - accountIndex: Account index
    /// - Returns: Balance as string
    public func getBalance(network: String, accountIndex: Int = 0) async throws -> String {
        let result = try await callMethod(
            methodName: "getBalance",
            network: network,
            accountIndex: accountIndex
        )
        
        guard let balance = result as? String else {
            throw WDKError.invalidResponse("Invalid balance format")
        }
        
        return balance
    }
}
