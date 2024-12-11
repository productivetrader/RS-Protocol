// Advanced inflation protection
contract RadialMigratorV3 is RadialMigratorV2 {
    uint256 public constant MAX_TOTAL_MIGRATION = 100_000_000 * 1e18; // Maximum total tokens
    uint256 public constant DAILY_MIGRATION_LIMIT = 1_000_000 * 1e18; // Daily migration limit
    
    mapping(uint256 => uint256) public dailyMigrated; // Track daily migrations
    
    function getDailyMigrated() public view returns (uint256) {
        return dailyMigrated[block.timestamp / 1 days];
    }
    
    function migrate(uint256 amount) external override whenNotPaused {
        require(totalMigrated + amount <= MAX_TOTAL_MIGRATION, "Exceeds total migration cap");
        
        uint256 today = block.timestamp / 1 days;
        uint256 dailyTotal = dailyMigrated[today] + amount;
        require(dailyTotal <= DAILY_MIGRATION_LIMIT, "Exceeds daily limit");
        
        dailyMigrated[today] = dailyTotal;
        
        super.migrate(amount);
    }
    
    // Add declining rate over time
    function getCurrentRate() public view override returns (uint256) {
        uint256 baseRate = super.getCurrentRate();
        uint256 timeElapsed = block.timestamp - startTime;
        uint256 decayFactor = timeElapsed / 30 days; // 30-day decay periods
        
        if (decayFactor > 0) {
            baseRate = baseRate * (95 ** decayFactor) / (100 ** decayFactor); // 5% decay per period
        }
        
        return baseRate;
    }
} 