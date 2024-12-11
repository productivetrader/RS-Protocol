// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./NRDLMigrationV3.sol";

contract NRDLMigrationBotDetection is NRDLMigrationV3 {
    struct InteractionPattern {
        uint256[] interactionTimestamps;    // Array of interaction timestamps
        uint256[] gasUsed;                  // Gas used in transactions
        uint256[] blockIntervals;           // Time between transactions
        uint256 regularTransactionCount;    // Normal transfers
        uint256 contractInteractionCount;   // Contract calls
        bool hasEOATransactions;            // Transactions with EOAs
        bool hasMultipleFailedTxs;          // Failed transaction attempts
        bool hasHumanLikeDelays;            // Irregular time intervals
    }

    mapping(address => InteractionPattern) public userPatterns;

    // Bot detection flags
    enum InteractionType {
        LIKELY_HUMAN,
        LIKELY_BOT,
        NEEDS_REVIEW
    }

    event BotDetected(address indexed account, string reason);
    event HumanVerified(address indexed account, string reason);

    function analyzeInteractionPattern(address user) public view returns (InteractionType) {
        InteractionPattern storage pattern = userPatterns[user];

        // Bot indicators
        bool hasUniformTiming = checkUniformTiming(pattern.blockIntervals);
        bool hasConstantGas = checkConstantGasUsage(pattern.gasUsed);
        bool hasRapidTransactions = checkTransactionSpeed(pattern.interactionTimestamps);
        
        // Human indicators
        bool hasVariableDelays = pattern.hasHumanLikeDelays;
        bool hasEOAInteraction = pattern.hasEOATransactions;
        bool hasFailedAttempts = pattern.hasMultipleFailedTxs;

        if (isBotPattern(hasUniformTiming, hasConstantGas, hasRapidTransactions)) {
            return InteractionType.LIKELY_BOT;
        } else if (isHumanPattern(hasVariableDelays, hasEOAInteraction, hasFailedAttempts)) {
            return InteractionType.LIKELY_HUMAN;
        }

        return InteractionType.NEEDS_REVIEW;
    }

    function isBotPattern(
        bool uniformTiming,
        bool constantGas,
        bool rapidTx
    ) internal pure returns (bool) {
        // Bots typically show:
        // 1. Uniform timing between transactions
        // 2. Consistent gas usage
        // 3. Rapid transaction sequences
        return (uniformTiming && constantGas) || (uniformTiming && rapidTx);
    }

    function isHumanPattern(
        bool variableDelays,
        bool hasEOAInteraction,
        bool hasFailures
    ) internal pure returns (bool) {
        // Humans typically show:
        // 1. Variable delays between actions
        // 2. Interactions with regular addresses
        // 3. Occasional failed transactions
        return (variableDelays && hasEOAInteraction) || (variableDelays && hasFailures);
    }

    function checkUniformTiming(uint256[] memory intervals) internal pure returns (bool) {
        if (intervals.length < 3) return false;
        
        uint256 tolerance = 2; // 2 second tolerance
        for (uint i = 1; i < intervals.length; i++) {
            if (abs(intervals[i] - intervals[i-1]) > tolerance) {
                return false;
            }
        }
        return true;
    }

    function checkConstantGasUsage(uint256[] memory gasUsed) internal pure returns (bool) {
        if (gasUsed.length < 3) return false;

        uint256 tolerance = 5000; // 5000 gas tolerance
        for (uint i = 1; i < gasUsed.length; i++) {
            if (abs(gasUsed[i] - gasUsed[i-1]) > tolerance) {
                return false;
            }
        }
        return true;
    }

    function checkTransactionSpeed(uint256[] memory timestamps) internal pure returns (bool) {
        if (timestamps.length < 3) return false;

        uint256 minHumanInterval = 2; // 2 seconds minimum for human interactions
        for (uint i = 1; i < timestamps.length; i++) {
            if (timestamps[i] - timestamps[i-1] < minHumanInterval) {
                return true; // Likely a bot due to very rapid transactions
            }
        }
        return false;
    }

    function abs(uint256 a) internal pure returns (uint256) {
        return a;
    }

    // Override migration to include bot detection
    function migrate(uint256 amount) external override {
        require(
            analyzeInteractionPattern(msg.sender) != InteractionType.LIKELY_BOT,
            "Bot-like activity detected"
        );
        super.migrate(amount);
    }
} 