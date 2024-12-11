// Enhanced migration rate mechanism
contract RadialMigratorV2 is RadialMigrator {
    struct RateSchedule {
        uint256 timestamp;
        uint256 rate;
    }
    
    RateSchedule[] public rateSchedule;
    
    function getCurrentRate() public view returns (uint256) {
        uint256 currentRate = migrationRate;
        for (uint i = 0; i < rateSchedule.length; i++) {
            if (block.timestamp >= rateSchedule[i].timestamp) {
                currentRate = rateSchedule[i].rate;
            }
        }
        return currentRate;
    }
    
    function addRateSchedule(uint256 timestamp, uint256 rate) external onlyOwner {
        require(timestamp > block.timestamp, "Timestamp must be in future");
        rateSchedule.push(RateSchedule(timestamp, rate));
    }
} 