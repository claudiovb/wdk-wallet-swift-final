import Foundation

/// Result types for WDK operations

/// Result from generating entropy and encrypting it
public struct EntropyResult {
    public let encryptionKey: String
    public let encryptedSeedBuffer: String
    public let encryptedEntropyBuffer: String
    
    public init(encryptionKey: String, encryptedSeedBuffer: String, encryptedEntropyBuffer: String) {
        self.encryptionKey = encryptionKey
        self.encryptedSeedBuffer = encryptedSeedBuffer
        self.encryptedEntropyBuffer = encryptedEntropyBuffer
    }
}

/// Result from converting mnemonic to encrypted seed and entropy
public struct SeedAndEntropyResult {
    public let encryptionKey: String
    public let encryptedSeedBuffer: String
    public let encryptedEntropyBuffer: String
    
    public init(encryptionKey: String, encryptedSeedBuffer: String, encryptedEntropyBuffer: String) {
        self.encryptionKey = encryptionKey
        self.encryptedSeedBuffer = encryptedSeedBuffer
        self.encryptedEntropyBuffer = encryptedEntropyBuffer
    }
}

/// Configuration for WDK initialization
public struct WDKConfig: Codable {
    public let networks: [String: NetworkConfig]
    public let protocols: [String: ProtocolConfig]?
    
    public init(networks: [String: NetworkConfig], protocols: [String: ProtocolConfig]? = nil) {
        self.networks = networks
        self.protocols = protocols
    }
    
    public struct NetworkConfig: Codable {
        // Network configuration can be a dictionary of any values
        // Actual structure depends on the network type (EVM, Solana, etc.)
        private let storage: [String: AnyCodable]
        
        public init(_ config: [String: Any]) {
            self.storage = config.mapValues { AnyCodable($0) }
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let dict = try container.decode([String: AnyCodable].self)
            self.storage = dict
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(storage)
        }
        
        public subscript(key: String) -> Any? {
            return storage[key]?.value
        }
    }
    
    public struct ProtocolConfig: Codable {
        public let network: String
        public let protocolLabel: String
        public let config: [String: AnyCodable]
        
        public init(network: String, protocolLabel: String, config: [String: Any]) {
            self.network = network
            self.protocolLabel = protocolLabel
            self.config = config.mapValues { AnyCodable($0) }
        }
    }
}

/// Helper for encoding Any values in Codable types
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let dict = value as? [String: Any] {
            let codableDict = dict.mapValues { AnyCodable($0) }
            try container.encode(codableDict)
        } else if let array = value as? [Any] {
            let codableArray = array.map { AnyCodable($0) }
            try container.encode(codableArray)
        } else {
            try container.encodeNil()
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else {
            value = ""
        }
    }
}
