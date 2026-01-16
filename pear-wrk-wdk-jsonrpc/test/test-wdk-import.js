/**
 * Test WDK import and basic initialization
 */

console.log('🧪 Testing WDK import...\n')

try {
  // Test different import methods
  console.log('1. Testing default import...')
  const WDKDefault = require('@tetherto/wdk')
  console.log('   Default export type:', typeof WDKDefault)
  console.log('   Default export:', WDKDefault)
  
  console.log('\n2. Testing destructured import...')
  const { WDK: WDKDestructured } = require('@tetherto/wdk')
  console.log('   Destructured type:', typeof WDKDestructured)
  console.log('   Destructured:', WDKDestructured)
  
  console.log('\n3. Checking which one is a constructor...')
  console.log('   WDKDefault is constructor?', typeof WDKDefault === 'function')
  console.log('   WDKDestructured is constructor?', typeof WDKDestructured === 'function')
  
  // Test wallet imports
  console.log('\n4. Testing wallet imports...')
  const EVMWallet = require('@tetherto/wdk-wallet-evm')
  const SolanaWallet = require('@tetherto/wdk-wallet-solana')
  const EVMERC4337Wallet = require('@tetherto/wdk-wallet-evm-erc-4337')
  
  console.log('   EVM Wallet type:', typeof EVMWallet)
  console.log('   Solana Wallet type:', typeof SolanaWallet)
  console.log('   ERC4337 Wallet type:', typeof EVMERC4337Wallet)
  
  // Try to initialize WDK
  console.log('\n5. Testing WDK initialization...')
  const seed = Buffer.alloc(64, 0) // Dummy seed
  
  // Check for .default property (ES module)
  console.log('   Checking for .default property...')
  const WDKConstructor = WDKDefault.default || WDKDefault
  console.log('   WDKConstructor type:', typeof WDKConstructor)
  
  if (typeof WDKConstructor === 'function') {
    console.log('   ✅ Found constructor!')
    const wdk = new WDKConstructor(seed)
    console.log('   ✅ WDK instance created:', !!wdk)
  } else {
    throw new Error('Could not find WDK constructor!')
  }
  
  console.log('\n✅ All tests passed!')
  
} catch (error) {
  console.error('\n❌ Error:', error.message)
  console.error('Stack:', error.stack)
  process.exit(1)
}
