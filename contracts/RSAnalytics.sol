// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RSAnalytics is Ownable {
    struct UserScore {
        uint256 lpScore;          // 0-40 points
        uint256 optionsScore;     // 0-30 points
        uint256 tradingScore;     // 0-20 points
        uint256 contributionScore;// 0-10 points
        uint256 totalScore;       // 0-100
        uint8 tier;               // 1-3, 0 if excluded
    }

    struct AnnualSnapshot {
        uint256 year;
        mapping(address => UserScore) scores;
        bool distributed;
    }

    mapping(uint256 => AnnualSnapshot) public annualSnapshots;
    mapping(address => UserScore) public currentScores;

    // Scoring thresholds
    uint256 public constant TIER1_THRESHOLD = 90;
    uint256 public constant TIER2_THRESHOLD = 80;
    uint256 public constant TIER3_THRESHOLD = 70;

    // Annual airdrop configuration
    uint256 public constant ANNUAL_AIRDROP_DAY = 12;
    uint256 public constant ANNUAL_AIRDROP_MONTH = 12;
    
    event ScoreUpdated(address user, uint256 newScore, uint8 newTier);
    event AnnualAirdropProcessed(uint256 year, uint256 totalRecipients);

    constructor() {
        // Initialize first year
        annualSnapshots[block.timestamp / 365 days].year = block.timestamp / 365 days;
    }

    // Score calculation functions
    function calculateLPScore(address user) public view returns (uint256) {
        // Score based on:
        // - Duration of LP provision
        // - Size of LP position
        // - Consistency of LP provision
        return _calculateLPMetrics(user);
    }

    function calculateOptionsScore(address user) public view returns (uint256) {
        // Score based on:
        // - Exercise vs. sell ratio
        // - Hold duration after exercise
        // - Reinvestment of profits
        return _calculateOptionsMetrics(user);
    }

    function calculateTradingScore(address user) public view returns (uint256) {
        // Score based on:
        // - Buy/sell ratio
        // - Price impact consideration
        // - Trading frequency
        return _calculateTradingMetrics(user);
    }

    function calculateContributionScore(address user) public view returns (uint256) {
        // Score based on:
        // - Governance participation
        // - Bug reports/fixes
        // - Community contribution
        return _calculateContributionMetrics(user);
    }

    // Update user scores
    function updateUserScore(address user) public {
        UserScore storage score = currentScores[user];
        
        score.lpScore = calculateLPScore(user);
        score.optionsScore = calculateOptionsScore(user);
        score.tradingScore = calculateTradingScore(user);
        score.contributionScore = calculateContributionScore(user);
        
        score.totalScore = score.lpScore + 
                          score.optionsScore + 
                          score.tradingScore + 
                          score.contributionScore;

        // Determine tier
        if (score.totalScore >= TIER1_THRESHOLD) {
            score.tier = 1;
        } else if (score.totalScore >= TIER2_THRESHOLD) {
            score.tier = 2;
        } else if (score.totalScore >= TIER3_THRESHOLD) {
            score.tier = 3;
        } else {
            score.tier = 0; // Excluded
        }

        emit ScoreUpdated(user, score.totalScore, score.tier);
    }

    // Process annual airdrop
    function processAnnualAirdrop() external onlyOwner {
        uint256 currentYear = block.timestamp / 365 days;
        AnnualSnapshot storage snapshot = annualSnapshots[currentYear];
        
        require(!snapshot.distributed, "Already distributed this year");
        require(
            block.timestamp.getMonth() == ANNUAL_AIRDROP_MONTH && 
            block.timestamp.getDay() == ANNUAL_AIRDROP_DAY,
            "Not airdrop day"
        );

        uint256 recipients;
        address[] memory users = _getActiveUsers();

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            // Copy current scores to snapshot
            snapshot.scores[user] = currentScores[user];
            if (currentScores[user].tier > 0) {
                recipients++;
                _issueAnnualOptions(user, currentScores[user].tier);
            }
        }

        snapshot.distributed = true;
        emit AnnualAirdropProcessed(currentYear, recipients);
    }

    // Calculate option amounts for annual airdrop
    function _issueAnnualOptions(address user, uint8 tier) internal {
        uint256 baseAmount = 1000 * 1e18; // 1000 RS base amount
        uint256 multiplier;
        
        if (tier == 1) {
            multiplier = 200; // 2x for Tier 1
        } else if (tier == 2) {
            multiplier = 150; // 1.5x for Tier 2
        } else {
            multiplier = 100; // 1x for Tier 3
        }

        uint256 optionAmount = (baseAmount * multiplier) / 100;
        optionsRewards.issueOptionReward(user, optionAmount, preferredPaymentToken[user]);
    }

    // View functions
    function getUserTier(address user) external view returns (uint8) {
        return currentScores[user].tier;
    }

    function getDetailedScore(address user) external view returns (
        uint256 lpScore,
        uint256 optionsScore,
        uint256 tradingScore,
        uint256 contributionScore,
        uint256 totalScore,
        uint8 tier
    ) {
        UserScore memory score = currentScores[user];
        return (
            score.lpScore,
            score.optionsScore,
            score.tradingScore,
            score.contributionScore,
            score.totalScore,
            score.tier
        );
    }
} 