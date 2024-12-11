#!/bin/bash

# Create new directory structure
mkdir -p contracts/active/core
mkdir -p contracts/active/analytics
mkdir -p contracts/active/treasury
mkdir -p contracts/active/interfaces
mkdir -p contracts/archived/rdl

# Move active contracts
mv contracts/RSDutchAuction.sol contracts/active/core/
mv contracts/RSOptionsRewards.sol contracts/active/core/
mv contracts/RSMasterChef.sol contracts/active/core/
mv contracts/RSAnalytics.sol contracts/active/analytics/
mv contracts/RSDistributionTracker.sol contracts/active/analytics/
mv contracts/RSTreasury.sol contracts/active/treasury/

# Move interfaces
mv contracts/interfaces/* contracts/active/interfaces/

# Archive RDL contracts
mv contracts/RDL*.sol contracts/archived/rdl/ 