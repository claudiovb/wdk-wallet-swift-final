console.log('wdk-worklet.js - JSON-RPC only version')

// Internal dependencies
const logger = require('./utils/logger')
const { handlers, withErrorHandling } = require('./rpc-handlers')

// Handle unhandled promise rejections and exceptions
if (typeof process !== 'undefined' && process.on) {
  process.on('unhandledRejection', (error) => {
    logger.error('Unhandled promise rejection in worklet:', error)
  })
  process.on('uncaughtException', (error) => {
    logger.error('Uncaught exception in worklet:', error)
  })
}

// Initialize BareKit IPC
// eslint-disable-next-line no-undef
const { IPC: BareIPC } = BareKit
logger.info('BareKit IPC initialized')

// State - this will be managed by the RPC handlers
let wdk = null

// Create context object for RPC handlers
// This allows handlers to read and update the wdk state
const context = {
  get wdk () {
    return wdk
  },
  set wdk (value) {
    wdk = value
  }
}

// Listen for incoming JSON-RPC messages
BareIPC.on('data', (data) => {
  try {
    const message = JSON.parse(data.toString())

    // Only handle if it's a JSON-RPC message (has 'jsonrpc' field)
    if (message.jsonrpc === '2.0') {
      handleJsonRpcMessage(message, context)
    }
  } catch (e) {
    logger.error('Failed to parse IPC message:', e)
  }
})

/**
 * Handle incoming JSON-RPC 2.0 messages
 * @param {Object} message - The JSON-RPC message
 * @param {Object} context - The context object with wdk state
 */
async function handleJsonRpcMessage (message, context) {
  const { id, method, params } = message

  try {
    let result
    logger.info(`JSON-RPC request: ${method}`, params)

    // Map JSON-RPC methods to handler functions
    switch (method) {
      case 'workletStart':
        result = await withErrorHandling(handlers.workletStart)()
        break

      case 'generateEntropyAndEncrypt':
        result = await withErrorHandling(handlers.generateEntropyAndEncrypt)(params)
        break

      case 'getMnemonicFromEntropy':
        result = await withErrorHandling(handlers.getMnemonicFromEntropy)(params)
        break

      case 'getSeedAndEntropyFromMnemonic':
        result = await withErrorHandling(handlers.getSeedAndEntropyFromMnemonic)(params)
        break

      case 'initializeWDK':
        result = await withErrorHandling(handlers.initializeWDK)(params, context)
        break

      case 'callMethod':
        result = await withErrorHandling(handlers.callMethod)(params, context)
        break

      case 'registerWallet':
        result = await withErrorHandling(handlers.registerWallet)(params, context)
        break

      case 'registerProtocol':
        result = await withErrorHandling(handlers.registerProtocol)(params, context)
        break

      case 'dispose':
        result = await withErrorHandling(handlers.dispose)(context)
        break

      default:
        throw new Error(`Unknown method: ${method}`)
    }

    logger.info(`JSON-RPC response: ${method}`, result)

    // Send success response
    BareIPC.write(JSON.stringify({
      jsonrpc: '2.0',
      id,
      result
    }))
  } catch (error) {
    logger.error(`JSON-RPC error: ${method}`, error)

    // Try to parse structured error if it exists (from withErrorHandling)
    let errorResponse
    try {
      const structuredError = JSON.parse(error.message)
      errorResponse = {
        message: structuredError.message,
        code: structuredError.code,
        data: structuredError.data
      }
    } catch (e) {
      // Not a structured error, use plain error
      errorResponse = {
        message: error.message || String(error),
        code: error.code || 'INTERNAL_ERROR'
      }
    }

    // Send error response
    BareIPC.write(JSON.stringify({
      jsonrpc: '2.0',
      id,
      error: errorResponse
    }))
  }
}

logger.info('WDK Worklet ready - listening for JSON-RPC messages')
