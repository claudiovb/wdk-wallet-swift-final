# IPC Framing Implementation

## Overview

Length-prefixed framing has been added to the IPC communication between Swift (WDKClient) and JavaScript (wdk-worklet) to ensure reliable message delivery in environments with multiple concurrent calls.

## The Problem

Without framing, IPC communication can suffer from:

- **Message fragmentation**: Large messages split across multiple reads
- **Message concatenation**: Multiple small messages combined in one read
- **Partial reads**: Reading incomplete JSON causing parse errors
- **Race conditions**: Concurrent calls getting mixed up

## The Solution

### Length-Prefixed Framing Protocol

Each message is prefixed with a 4-byte length header:

```
┌─────────────┬──────────────────┐
│  4 bytes    │    N bytes       │
│  Length     │    Message       │
│  (UInt32BE) │    (JSON)        │
└─────────────┴──────────────────┘
```

**Example:**

```
Message: {"jsonrpc":"2.0","id":1}
Length: 26 bytes

Wire format:
[0x00, 0x00, 0x00, 0x1A, '{', '"', 'j', 's', 'o', 'n', ...]
 └─── 4-byte length ───┘  └────── 26-byte message ──────┘
```

## Implementation

### JavaScript Side (`wdk-worklet.js`)

**Write:**

```javascript
function writeFramed(data) {
  const length = Buffer.allocUnsafe(4);
  length.writeUInt32BE(data.length, 0);
  BareIPC.write(Buffer.concat([length, data]));
}
```

**Read:**

```javascript
let readBuffer = Buffer.alloc(0);

function processFramedData(chunk) {
  // Append to buffer
  readBuffer = Buffer.concat([readBuffer, chunk]);

  // Extract complete messages
  while (readBuffer.length >= 4) {
    const messageLength = readBuffer.readUInt32BE(0);
    const totalLength = 4 + messageLength;

    if (readBuffer.length < totalLength) break;

    const messageData = readBuffer.slice(4, totalLength);
    readBuffer = readBuffer.slice(totalLength);

    // Process message...
  }
}
```

### Swift Side (`WDKClient.swift`)

**Write:**

```swift
private func writeFramed(data: Data) async throws {
    var length = UInt32(data.count).bigEndian
    let lengthData = Data(bytes: &length, count: 4)
    try await ipc.write(data: lengthData + data)
}
```

**Read:**

```swift
private func readFramed() async throws -> Data {
    // Read 4-byte length header
    let lengthData = try await readExactly(bytes: 4)
    let length = lengthData.withUnsafeBytes {
        $0.load(as: UInt32.self).bigEndian
    }

    // Read exact message length
    return try await readExactly(bytes: Int(length))
}

private func readExactly(bytes: Int) async throws -> Data {
    // Keep reading and buffering until we have enough bytes
    while readBuffer.count < bytes {
        guard let chunk = try await ipc.read() else {
            throw WDKError.ipcError("Connection closed")
        }
        readBuffer.append(chunk)
    }

    let result = readBuffer.prefix(bytes)
    readBuffer = readBuffer.dropFirst(bytes)
    return Data(result)
}
```

## Features

### ✅ Handles Message Fragmentation

Large messages split across multiple IPC reads are correctly reassembled:

```
Send: [length:1000][...1000 bytes...]
Receive chunks: [100 bytes] + [400 bytes] + [500 bytes]
Result: Complete 1000-byte message ✓
```

### ✅ Handles Message Concatenation

Multiple messages in one IPC read are correctly extracted:

```
Receive: [len:10][msg1][len:20][msg2][len:15][msg3]
Result: 3 separate messages ✓
```

### ✅ Handles Partial Headers

Length header split across reads is buffered correctly:

```
Receive: [0x00, 0x00] + [0x00, 0x1A, '{', ...]
Result: Complete message with length 26 ✓
```

### ✅ Message Size Validation

- Maximum message size: 10MB (configurable)
- Prevents memory exhaustion attacks
- Validates length before allocation

## Testing

### Framing Unit Tests

Run the framing tests:

```bash
cd pear-wrk-wdk-jsonrpc
bare test/test-framing.js
```

Tests cover:

1. ✅ Single complete message
2. ✅ Multiple messages in one chunk
3. ✅ Fragmented messages across chunks
4. ✅ Partial length header
5. ✅ Empty messages
6. ✅ Large messages (1MB+)
7. ✅ Real JSON-RPC messages

### Integration Testing

Test in the iOS demo app:

1. Build and run the app in Xcode
2. Observe successful address retrieval
3. Test with multiple concurrent calls
4. Check for no JSON parse errors in logs

## Specification

### Wire Protocol

| Field   | Type                | Size     | Description         |
| ------- | ------------------- | -------- | ------------------- |
| Length  | UInt32 (Big-Endian) | 4 bytes  | Message body length |
| Message | UTF-8 JSON          | Variable | JSON-RPC message    |

### Constraints

- **Minimum message size**: 0 bytes (empty message)
- **Maximum message size**: 10,000,000 bytes (10MB)
- **Byte order**: Big-endian (network byte order)
- **Encoding**: UTF-8 JSON

### Error Handling

| Error             | Cause                             | Action                        |
| ----------------- | --------------------------------- | ----------------------------- |
| Invalid length    | Length > 10MB or length < 0       | Throw error, close connection |
| Connection closed | IPC read returns null mid-message | Throw error with context      |
| Parse error       | Invalid JSON after framing        | Log error, skip message       |

## Performance

### Overhead

- **Per-message overhead**: 4 bytes (0.4% for 1KB message)
- **Memory overhead**: One read buffer per connection (~small)
- **CPU overhead**: Minimal (buffer concatenation + slicing)

### Benefits

- **Reduced syscalls**: Batching multiple messages
- **No scanning**: No need to scan for delimiters
- **Predictable**: Always know how much to read

## Backward Compatibility

⚠️ **Breaking Change**: This changes the wire protocol. Both Swift and JavaScript sides must be updated together. The framing was added in a single commit to maintain consistency.

## Future Enhancements

Potential improvements (not currently needed):

1. **Magic bytes**: Add header magic bytes for protocol version detection
2. **Checksums**: Add CRC32 or similar for message integrity
3. **Compression**: Add optional compression flag and compressed payload
4. **Multiplexing**: Add stream/channel ID for multiplexing multiple logical streams

## References

- Protocol similar to: gRPC, Protocol Buffers, MessagePack
- Alternative approaches considered: Newline-delimited JSON, fixed-size messages
- Chosen for: Simplicity, efficiency, standard practice
