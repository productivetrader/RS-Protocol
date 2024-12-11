// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./RadialMigratorV3.sol";

contract NRDLMasterChefMigration is RadialMigratorV3 {
    // Snapshot block for rewards calculation
    uint256 public immutable SNAPSHOT_BLOCK;
    // Maximum rewards cap per user
    uint256 public constant MAX_REWARDS_CAP = 100_000 * 1e18; // 100k tokens
    // Decay factor for old rewards
    uint256 public constant DECAY_RATE = 50; // 50% reduction
    
    struct UserRewards {
        uint256 originalAmount;
        uint256 adjustedAmount;
        bool hasMigrated;
    }
    
    mapping(address => UserRewards) public userRewards;
    
    constructor(uint256 _snapshotBlock) {
        SNAPSHOT_BLOCK = _snapshotBlock;
    }
    
    function calculateAdjustedRewards(
        address user,
        uint256 originalAmount
    ) public view returns (uint256) {
        // Base reduction for all old rewards
        uint256 adjustedAmount = (originalAmount * DECAY_RATE) / 100;
        
        // Apply progressive reduction for large amounts
        if (adjustedAmount > MAX_REWARDS_CAP) {
            uint256 excess = adjustedAmount - MAX_REWARDS_CAP;
            // Additional 75% reduction on excess
            adjustedAmount = MAX_REWARDS_CAP + (excess * 25) / 100;
        }
        
        return adjustedAmount;
    }
    
    function migrateRewards(uint256 originalAmount) external {
        require(!userRewards[msg.sender].hasMigrated, "Already migrated");
        require(originalAmount > 0, "No rewards to migrate");
        
        uint256 adjustedAmount = calculateAdjustedRewards(msg.sender, originalAmount);
        
        userRewards[msg.sender] = UserRewards({
            originalAmount: originalAmount,
            adjustedAmount: adjustedAmount,
            hasMigrated: true
        });
        
        // Transfer adjusted rewards
        newToken.transfer(msg.sender, adjustedAmount);
        oldToken.transferFrom(msg.sender, address(0), originalAmount); // Burn old tokens
    }
} 