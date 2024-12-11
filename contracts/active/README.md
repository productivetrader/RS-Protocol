# Active RS Token Contracts

## Core Contracts

### RSDutchAuction.sol

- Purpose: Initial RS token distribution and price discovery
- Allocation: 20M RS tokens
- Key Features:
  - Fair launch mechanism
  - Initial liquidity establishment
  - Price discovery

### RSOptionsRewards.sol

- Purpose: Manages all RS token options
- Handles:
  - Team options (1M RS)
  - LP incentives (40M RS)
  - Annual bonus options (21M RS)
  - Strike price calculations
  - Exercise mechanics

### RSMasterChef.sol

- Purpose: LP staking and rewards
- Features:
  - LP token staking
  - Options rewards distribution
  - Pool management

## Analytics Contracts

### RSAnalytics.sol

- Purpose: Behavior tracking and scoring
- Tracks:
  - Protocol participation
  - LP provision
  - Options exercise patterns
  - Community contribution

### RSDistributionTracker.sol

- Purpose: Distribution phase management
- Tracks:
  - All distribution phases
  - Token allocations
  - Completion status

## Treasury Contract

### RSTreasury.sol

- Purpose: Protocol treasury management
- Allocation: 4M RS tokens
- Features:
  - Protocol development funding
  - Operational management
  - Transparent tracking

## Integration Flow

1. Dutch Auction establishes initial price and liquidity
2. Options system provides ongoing incentives
3. MasterChef manages LP staking
4. Analytics tracks behavior
5. Distribution Tracker monitors all phases
6. Treasury supports protocol development

## Security

All active contracts are:

- Audited
- Actively maintained
- Monitored for unusual activity
