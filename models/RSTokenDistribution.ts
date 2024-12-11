interface TokenDistribution {
  maxSupply: 100_000_000; // Fixed supply, no inflation

  // Phase 1: First Retroactive Airdrop (7M - 7%)
  firstRetroactiveAirdrop: {
    amount: 7_000_000;
    timing: "T-7 days before auction";
    recipients: "RDL holders from migration list";
  };

  // Phase 2: Team Options (1M - 1%)
  teamOptions: {
    amount: 1_000_000;
    strikeDiscount: "50%";
    exerciseWindow: "30 days post-auction";
  };

  // Phase 3: Dutch Auction (20M - 20%)
  dutchAuction: {
    amount: 20_000_000;
    purpose: "Initial liquidity and price discovery";
  };

  // Phase 4: Second Retroactive Airdrop (7M - 7%)
  secondRetroactiveAirdrop: {
    amount: 7_000_000;
    timing: "Admin configured";
    recipients: "Based on tracked pro-protocol behavior";
  };

  // Phase 5: Annual Bonus Program (21M - 21%)
  annualBonusProgram: {
    total: 21_000_000;
    yearlyAllocation: 3_000_000;
    duration: "7 years";
    format: "Options based on continued pro-protocol behavior";
  };

  // Phase 6: LP Incentives (40M - 40%)
  lpIncentives: {
    total: 40_000_000;
    yearlyAllocation: 5_714_285; // ~5.71M per year
    duration: "7 years";
    format: "Options";
  };

  // Phase 7: Treasury (4M - 4%)
  treasury: {
    amount: 4_000_000;
    purpose: "Protocol development and operations";
  };

  // Total: 100M (100%)
}
