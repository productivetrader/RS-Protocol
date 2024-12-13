# RS Protocol Deployment Test Guide

## Test Scripts Overview

After deploying the contracts to Sonic Blaze testnet, run these test scripts in sequence:

```bash
# 1. Verify basic deployment and token configuration
npx hardhat run scripts/test/deployment-verification.js --network sonic

# 2. Test core protocol functionality
npx hardhat run scripts/test/core-functionality.js --network sonic

# 3. Test analytics and treasury systems
npx hardhat run scripts/test/analytics-treasury-tests.js --network sonic
```

## What Each Test Covers

### 1. Deployment Verification

- RSToken configuration
- Token allocations
- Admin roles setup
- Initial supply verification

### 2. Core Functionality

- Dutch Auction mechanics
- Price decay verification
- Options system functionality
- Strike price calculations

### 3. Analytics & Treasury

- Analytics scoring system
- Distribution tracking
- MasterChef pool management
- Treasury controls
- Spending tracking

## Important Notes

- Ensure all contract addresses are updated in test scripts after deployment
- Run tests in sequence to ensure proper initialization
- Monitor gas usage during testing
- Keep track of test results for mainnet preparation

## Test Requirements

- Admin wallet with sufficient S tokens
- Updated .env configuration
- Hardhat network properly configured for Sonic Blaze
