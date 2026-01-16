#!/usr/bin/env node

const { execSync } = require('child_process')
const path = require('path')

// List of bare modules that need to be linked for iOS
const bareModules = [
  'bare-fs',
  'bare-inspect',
  'bare-type',
  'sodium-native',
  'bare-url',
  'bare-hrtime',
  'bare-tty',
  'bare-signals',
  'bare-os',
  'bare-performance',
  'bare-zlib',
  'bare-pipe',
  'bare-tls',
  'bare-tcp',
  'bare-dns',
  'bare-crypto'
]

const hosts = [
  'ios-arm64',
  'ios-arm64-simulator',
  'ios-x64-simulator'
]

const outDir = 'ios-addons'

console.log('🔗 Linking Bare addons for iOS...\n')

for (const module of bareModules) {
  const modulePath = path.join('node_modules', module)
  
  try {
    console.log(`  Linking ${module}...`)
    
    const hostsArgs = hosts.map(h => `--host ${h}`).join(' ')
    const command = `npx bare-link ${hostsArgs} --out ${outDir} ${modulePath}`
    
    execSync(command, { 
      stdio: 'inherit',
      cwd: process.cwd()
    })
    
    console.log(`  ✅ ${module} linked successfully\n`)
  } catch (error) {
    console.error(`  ❌ Failed to link ${module}:`, error.message)
    process.exit(1)
  }
}

console.log('✨ All Bare addons linked successfully!')
