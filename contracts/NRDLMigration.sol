// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./RadialMigratorV3.sol";

contract NRDLMigration is RadialMigratorV3 {
    // Migration types
    enum MigrationType { STANDARD, VESTED, BURN }
    
    struct MigrationConfig {
        MigrationType migrationType;
        uint256 vestingDuration;
        uint256 migrationRate;
        bool isActive;
    }
    
    // Configuration for each contract type
    mapping(address => MigrationConfig) public migrationConfigs;
    
    // Vesting tracking
    mapping(address => uint256) public vestingStart;
    mapping(address => uint256) public vestedAmount;
    
    event MigrationConfigSet(address indexed contract_, MigrationType migrationType);
    
    function setMigrationConfig(
        address contract_,
        MigrationType migrationType,
        uint256 vestingDuration,
        uint256 migrationRate
    ) external onlyOwner {
        migrationConfigs[contract_] = MigrationConfig({
            migrationType: migrationType,
            vestingDuration: vestingDuration,
            migrationRate: migrationRate,
            isActive: true
        });
        
        emit MigrationConfigSet(contract_, migrationType);
    }
    
    function migrate(uint256 amount) public override {
        MigrationConfig memory config = migrationConfigs[msg.sender];
        require(config.isActive, "Migration not configured");
        
        if (config.migrationType == MigrationType.BURN) {
            // Burn tokens
            oldToken.safeTransferFrom(msg.sender, address(0), amount);
            emit TokensBurned(msg.sender, amount);
        } 
        else if (config.migrationType == MigrationType.VESTED) {
            // Start vesting
            _handleVestedMigration(amount, config);
        }
        else {
            // Standard migration
            super.migrate(amount);
        }
    }
    
    function _handleVestedMigration(uint256 amount, MigrationConfig memory config) internal {
        // Implementation for vested migration
        vestingStart[msg.sender] = block.timestamp;
        vestedAmount[msg.sender] = amount;
        // ... vesting logic
    }
} 