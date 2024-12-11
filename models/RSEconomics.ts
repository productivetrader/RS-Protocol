interface EconomicModel {
  initialSupply: 100_000_000;
  distribution: {
    // Phase 1: First Retroactive + Team
    firstRetroactive: {
      amount: 7_000_000; // 7% - Direct airdrop for RDL holders
      timing: "T-7 days before auction";
      tracking: true; // Monitor holder behavior
    };
    teamAllocation: {
      amount: 1_000_000; // 1% - Team options
      format: "Options";
      strikeDiscount: "50%";
      exerciseWindow: "30 days post-auction";
      tracking: true; // Monitor exercise patterns
    };

    // Phase 2: Dutch Auction
    dutchAuction: {
      amount: 20_000_000; // 20%
      duration: "7 days";
    };

    // Phase 3: Long-term Incentives
    lpIncentives: {
      amount: 40_000_000; // 40%
      duration: "7 years";
      distribution: "Adjustable yearly rate";
      format: "Options";
    };

    // Phase 4: Annual Program
    annualBonus: {
      amount: 25_000_000; // 25% for annual airdrops
      perYear: "~3.57M"; // 25M/7 years
      secondRetroactive: {
        amount: 7_000_000; // First year special distribution
        adminConfigurable: true;
        targetAreas: [
          "Business Development",
          "Marketing",
          "PR",
          "Community Building"
        ];
      };
    };
  };

  // Annual Distribution Schedule (7 years)
  annualSchedule: {
    lpRewards: {
      yearlyPool: "5.71M"; // 40M/7 years
      adjustmentMechanism: "Quarterly review";
      minimumRate: "2M/year";
      maximumRate: "8M/year";
    };
    bonusPool: {
      baseYearly: "3.57M"; // 25M/7 years
      adjustmentRange: "±20%";
      criteria: "Configurable by Admin";
    };
  };
}
