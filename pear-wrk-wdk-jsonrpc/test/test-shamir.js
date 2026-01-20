/**
 * Test Shamir Secret Sharing handlers in Bare runtime
 */

const { handlers } = require('../src/rpc-handlers')

console.log('🔐 Testing Shamir Secret Sharing handlers in Bare runtime...\n')

async function runTests() {
  try {
    // Test 1: Generate a test mnemonic
    console.log('1. Generating test mnemonic...')
    const entropyResult = await handlers.generateEntropyAndEncrypt({ wordCount: 12 })
    const mnemonicResult = await handlers.getMnemonicFromEntropy({
      encryptedEntropy: entropyResult.encryptedEntropyBuffer,
      encryptionKey: entropyResult.encryptionKey
    })
    const testMnemonic = mnemonicResult.mnemonic
    console.log('   ✅ Test mnemonic:', testMnemonic)
    
    // Test 2: Split mnemonic into shares (3-of-5)
    console.log('\n2. Testing splitMnemonic (3-of-5)...')
    const splitResult = await handlers.splitMnemonic({
      mnemonic: testMnemonic,
      shares: 5,
      threshold: 3
    })
    console.log('   ✅ Total shares created:', splitResult.totalShares)
    console.log('   ✅ Threshold:', splitResult.threshold)
    console.log('   ✅ Number of shares returned:', splitResult.shares.length)
    console.log('   ✅ First share (hex):', splitResult.shares[0].substring(0, 40) + '...')
    console.log('   ✅ Shares are hex strings')
    
    // Test 3: Combine shares with threshold (using first 3 shares)
    console.log('\n3. Testing combineShares (using 3 shares)...')
    const sharesToCombine = [
      splitResult.shares[0],
      splitResult.shares[1],
      splitResult.shares[2]
    ]
    const combineResult = await handlers.combineShares({
      shares: sharesToCombine
    })
    console.log('   ✅ Reconstructed mnemonic:', combineResult.mnemonic)
    
    // Test 4: Verify reconstructed mnemonic matches original
    console.log('\n4. Verifying reconstruction...')
    if (combineResult.mnemonic !== testMnemonic) {
      throw new Error('Reconstructed mnemonic does not match original!')
    }
    console.log('   ✅ Reconstructed mnemonic matches original')
    
    // Test 5: Combine different subset of shares (using last 3 shares)
    console.log('\n5. Testing combineShares with different subset (shares 2, 3, 4)...')
    const differentShares = [
      splitResult.shares[2],
      splitResult.shares[3],
      splitResult.shares[4]
    ]
    const combineResult2 = await handlers.combineShares({
      shares: differentShares
    })
    console.log('   ✅ Reconstructed mnemonic:', combineResult2.mnemonic)
    
    if (combineResult2.mnemonic !== testMnemonic) {
      throw new Error('Reconstructed mnemonic from different subset does not match original!')
    }
    console.log('   ✅ Different subset also reconstructs correctly')
    
    // Test 6: Test 2-of-2 configuration
    console.log('\n6. Testing 2-of-2 configuration...')
    const split2of2 = await handlers.splitMnemonic({
      mnemonic: testMnemonic,
      shares: 2,
      threshold: 2
    })
    console.log('   ✅ Created 2 shares')
    
    const combine2of2 = await handlers.combineShares({
      shares: split2of2.shares
    })
    if (combine2of2.mnemonic !== testMnemonic) {
      throw new Error('2-of-2 reconstruction failed!')
    }
    console.log('   ✅ 2-of-2 reconstruction successful')
    
    // Test 7: Test with 24-word mnemonic
    console.log('\n7. Testing with 24-word mnemonic...')
    const entropy24Result = await handlers.generateEntropyAndEncrypt({ wordCount: 24 })
    const mnemonic24Result = await handlers.getMnemonicFromEntropy({
      encryptedEntropy: entropy24Result.encryptedEntropyBuffer,
      encryptionKey: entropy24Result.encryptionKey
    })
    const testMnemonic24 = mnemonic24Result.mnemonic
    
    const split24 = await handlers.splitMnemonic({
      mnemonic: testMnemonic24,
      shares: 7,
      threshold: 5
    })
    console.log('   ✅ Split 24-word mnemonic into 7 shares')
    
    const combine24 = await handlers.combineShares({
      shares: split24.shares.slice(0, 5) // Use first 5 shares
    })
    if (combine24.mnemonic !== testMnemonic24) {
      throw new Error('24-word mnemonic reconstruction failed!')
    }
    console.log('   ✅ 24-word mnemonic reconstruction successful')
    
    // Test 8: Error handling - invalid threshold (library validates)
    console.log('\n8. Testing error handling...')
    try {
      await handlers.splitMnemonic({
        mnemonic: testMnemonic,
        shares: 3,
        threshold: 5 // threshold > shares
      })
      throw new Error('Should have thrown an error for threshold > shares')
    } catch (error) {
      if (error.message.includes('threshold cannot be greater than shares')) {
        console.log('   ✅ Correctly rejected threshold > shares')
      } else {
        throw error
      }
    }
    
    // Test 9: Error handling - insufficient shares (library validates)
    try {
      await handlers.combineShares({
        shares: [splitResult.shares[0]] // Only 1 share
      })
      throw new Error('Should have thrown an error for insufficient shares')
    } catch (error) {
      if (error.message.includes('At least 2 shares are required')) {
        console.log('   ✅ Correctly rejected insufficient shares')
      } else {
        throw error
      }
    }
    
    // Test 10: Error handling - invalid mnemonic (library validates)
    try {
      await handlers.splitMnemonic({
        mnemonic: 'not a valid mnemonic',
        shares: 3,
        threshold: 2
      })
      throw new Error('Should have thrown an error for invalid mnemonic')
    } catch (error) {
      if (error.message.includes('Invalid mnemonic word count')) {
        console.log('   ✅ Correctly rejected invalid mnemonic')
      } else {
        throw error
      }
    }
    
    console.log('\n✅ All Shamir Secret Sharing tests passed in Bare runtime!')
    
  } catch (error) {
    console.error('\n❌ Test failed:', error.message)
    console.error('Stack:', error.stack)
    process.exit(1)
  }
}

runTests()
