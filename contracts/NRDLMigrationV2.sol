// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./RadialMigratorV3.sol";

contract NRDLMigrationV2 is RadialMigratorV3 {
    enum HolderType {
        REGULAR_HOLDER,    // Regular wallet holding RDL
        MASTERCHEF_REWARDS, // Inflated rewards from staking
        TEAM_ALLOCATION    // Team tokens
    }
    
    mapping(address => HolderType) public holderTypes;
    
    // Regular holders get 1:1 migration
    function migrateRegularHolder(uint256 amount) external {
        require(holderTypes[msg.sender] == HolderType.REGULAR_HOLDER, "Not a regular holder");
        require(amount > 0, "Amount must be greater than 0");
        
        // Simple 1:1 migration for regular holders
        oldToken.transferFrom(msg.sender, address(this), amount);
        newToken.transfer(msg.sender, amount); // 1:1 ratio
        
        emit TokensMigrated(msg.sender, amount, amount);
    }
    
    // Inflated rewards get reduced
    function migrateMasterChefRewards(uint256 amount) external {
        require(holderTypes[msg.sender] == HolderType.MASTERCHEF_REWARDS, "Not from MasterChef");
        
        // Calculate base holding vs inflated rewards
        uint256 baseHolding = getBaseHolding(msg.sender);
        uint256 inflatedAmount = amount - baseHolding;
        
        // Base holdings migrate 1:1
        uint256 newAmount = baseHolding;
        
        // Only apply reduction to inflated portion
        if (inflatedAmount > 0) {
            newAmount += calculateReducedInflation(inflatedAmount);
        }
        
        oldToken.transferFrom(msg.sender, address(this), amount);
        newToken.transfer(msg.sender, newAmount);
        
        emit TokensMigrated(msg.sender, amount, newAmount);
    }
    
    function getBaseHolding(address holder) internal view returns (uint256) {
        // Implementation to determine original holding amount
        // This could be from a snapshot or historical data
    }
    
    function calculateReducedInflation(uint256 inflatedAmount) internal pure returns (uint256) {
        // Apply reduction only to inflated portion
        return inflatedAmount * 25 / 100; // 75% reduction on inflated portion
    }
    
    // Admin function to set holder types
    function setHolderType(address holder, HolderType holderType) external onlyOwner {
        holderTypes[holder] = holderType;
        emit HolderTypeSet(holder, holderType);
    }
    
    event HolderTypeSet(address indexed holder, HolderType holderType);
} 