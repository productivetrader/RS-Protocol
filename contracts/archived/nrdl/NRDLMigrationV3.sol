// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./RadialMigratorV3.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract NRDLMigrationV3 is RadialMigratorV3 {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum HolderType {
        UNVERIFIED,
        REGULAR_HOLDER,
        MASTERCHEF_REWARDS,
        TEAM_ALLOCATION
    }

    struct HolderData {
        HolderType holderType;
        uint256 baseHolding;      // Original holding amount
        uint256 inflatedAmount;   // Rewards from staking/farming
        uint256 lastSnapshotBlock;
        bool isVerified;
    }

    // Tracking structures
    mapping(address => HolderData) public holderData;
    EnumerableSet.AddressSet private regularHolders;
    EnumerableSet.AddressSet private masterChefUsers;

    // Verification and tracking
    uint256 public immutable SNAPSHOT_BLOCK;
    uint256 public constant VERIFICATION_THRESHOLD = 7 days;
    mapping(address => uint256) public verificationRequests;

    event HolderVerified(address indexed holder, HolderType holderType);
    event BaseHoldingUpdated(address indexed holder, uint256 amount);
    event InflatedAmountUpdated(address indexed holder, uint256 amount);
    event MigrationProcessed(
        address indexed holder,
        uint256 baseAmount,
        uint256 inflatedAmount,
        uint256 totalNewTokens
    );

    constructor(uint256 _snapshotBlock) {
        SNAPSHOT_BLOCK = _snapshotBlock;
    }

    // 1. Enhanced Tracking System
    function updateHolderData(
        address holder,
        uint256 baseAmount,
        uint256 inflatedAmount
    ) external onlyOwner {
        HolderData storage data = holderData[holder];
        data.baseHolding = baseAmount;
        data.inflatedAmount = inflatedAmount;
        data.lastSnapshotBlock = block.number;

        emit BaseHoldingUpdated(holder, baseAmount);
        emit InflatedAmountUpdated(holder, inflatedAmount);
    }

    // 2. Verification System
    function requestVerification() external {
        require(verificationRequests[msg.sender] == 0, "Verification already requested");
        require(holderData[msg.sender].holderType == HolderType.UNVERIFIED, "Already verified");
        
        verificationRequests[msg.sender] = block.timestamp;
    }

    function verifyHolder(address holder) external onlyOwner {
        require(verificationRequests[holder] > 0, "No verification requested");
        require(
            block.timestamp >= verificationRequests[holder] + VERIFICATION_THRESHOLD,
            "Verification period not ended"
        );

        HolderData storage data = holderData[holder];
        
        // Verify holder type based on historical data
        if (wasInMasterChef(holder)) {
            data.holderType = HolderType.MASTERCHEF_REWARDS;
            masterChefUsers.add(holder);
        } else {
            data.holderType = HolderType.REGULAR_HOLDER;
            regularHolders.add(holder);
        }
        
        data.isVerified = true;
        emit HolderVerified(holder, data.holderType);
    }

    // 3. Transparency Features
    function getHolderStats(address holder) external view returns (
        HolderType holderType,
        uint256 baseHolding,
        uint256 inflatedAmount,
        bool isVerified,
        uint256 potentialNewTokens
    ) {
        HolderData storage data = holderData[holder];
        uint256 newTokens = calculateMigrationAmount(holder);
        
        return (
            data.holderType,
            data.baseHolding,
            data.inflatedAmount,
            data.isVerified,
            newTokens
        );
    }

    function getHolderCounts() external view returns (
        uint256 regularHoldersCount,
        uint256 masterChefUsersCount
    ) {
        return (
            regularHolders.length(),
            masterChefUsers.length()
        );
    }

    // Migration logic
    function migrate(uint256 amount) external override {
        require(holderData[msg.sender].isVerified, "Holder not verified");
        
        uint256 newTokens = calculateMigrationAmount(msg.sender);
        require(newTokens > 0, "No tokens eligible for migration");

        // Process migration
        oldToken.transferFrom(msg.sender, address(this), amount);
        newToken.transfer(msg.sender, newTokens);

        emit MigrationProcessed(
            msg.sender,
            holderData[msg.sender].baseHolding,
            holderData[msg.sender].inflatedAmount,
            newTokens
        );
    }

    // Internal helper functions
    function calculateMigrationAmount(address holder) internal view returns (uint256) {
        HolderData storage data = holderData[holder];
        
        if (data.holderType == HolderType.REGULAR_HOLDER) {
            return data.baseHolding; // 1:1 migration
        } else if (data.holderType == HolderType.MASTERCHEF_REWARDS) {
            return data.baseHolding + (data.inflatedAmount * 25 / 100); // Base + 25% of inflated
        }
        return 0;
    }

    function wasInMasterChef(address holder) internal view returns (bool) {
        // Implementation to check historical MasterChef participation
        // This would query historical blockchain data or use stored snapshots
    }
} 