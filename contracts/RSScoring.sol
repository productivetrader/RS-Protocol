library RSScoring {
    struct LPMetrics {
        uint256 duration;
        uint256 size;
        uint256 consistency;
    }

    struct OptionsMetrics {
        uint256 exerciseRatio;
        uint256 holdDuration;
        uint256 reinvestment;
    }

    function calculateLPScore(LPMetrics memory metrics) internal pure returns (uint256) {
        // Max 40 points
        uint256 durationScore = (metrics.duration * 15) / MAX_DURATION;
        uint256 sizeScore = (metrics.size * 15) / MAX_SIZE;
        uint256 consistencyScore = (metrics.consistency * 10) / MAX_CONSISTENCY;
        
        return durationScore + sizeScore + consistencyScore;
    }

    function calculateOptionsScore(OptionsMetrics memory metrics) internal pure returns (uint256) {
        // Max 30 points
        uint256 exerciseScore = (metrics.exerciseRatio * 15) / MAX_RATIO;
        uint256 holdScore = (metrics.holdDuration * 10) / MAX_HOLD;
        uint256 reinvestScore = (metrics.reinvestment * 5) / MAX_REINVEST;
        
        return exerciseScore + holdScore + reinvestScore;
    }
} 