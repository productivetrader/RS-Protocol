import { ethers } from "hardhat";
import { BigNumber } from "ethers";

interface UserActivity {
  address: string;
  lpHistory: {
    amount: BigNumber;
    duration: number;
    entries: number;
  };
  optionsHistory: {
    exercised: number;
    held: number;
    reinvested: number;
  };
  tradingHistory: {
    buys: number;
    sells: number;
    avgImpact: number;
  };
  contributions: {
    governance: number;
    community: number;
    development: number;
  };
}

async function simulateAnnualDistribution() {
  console.log("Simulating Annual RS Distribution 2024\n");

  // Sample user activities (would be fetched from chain in production)
  const userActivities: UserActivity[] = [
    {
      address: "0x1234...5678",
      lpHistory: {
        amount: ethers.utils.parseEther("50000"),
        duration: 350, // days
        entries: 12, // consistent monthly adds
      },
      optionsHistory: {
        exercised: 15,
        held: 280, // avg hold duration
        reinvested: 12,
      },
      tradingHistory: {
        buys: 25,
        sells: 5,
        avgImpact: 0.1,
      },
      contributions: {
        governance: 15, // votes
        community: 8, // contributions
        development: 2, // improvements
      },
    },
    // ... more users
  ];

  console.log("Processing User Scores...\n");

  let results = {
    tier1: { count: 0, totalRewards: BigNumber.from(0) },
    tier2: { count: 0, totalRewards: BigNumber.from(0) },
    tier3: { count: 0, totalRewards: BigNumber.from(0) },
    excluded: { count: 0 },
  };

  for (const user of userActivities) {
    const score = calculateUserScore(user);
    const tier = determineUserTier(score);
    const reward = calculateReward(tier);

    console.log(`\nAddress: ${user.address}`);
    console.log(`Total Score: ${score}/100`);
    console.log(`Tier: ${tier}`);
    console.log("Breakdown:");
    console.log(`- LP Score: ${calculateLPScore(user.lpHistory)}/40`);
    console.log(
      `- Options Score: ${calculateOptionsScore(user.optionsHistory)}/30`
    );
    console.log(
      `- Trading Score: ${calculateTradingScore(user.tradingHistory)}/20`
    );
    console.log(
      `- Contribution Score: ${calculateContributionScore(
        user.contributions
      )}/10`
    );

    if (tier === 1) {
      results.tier1.count++;
      results.tier1.totalRewards = results.tier1.totalRewards.add(reward);
    } else if (tier === 2) {
      results.tier2.count++;
      results.tier2.totalRewards = results.tier2.totalRewards.add(reward);
    } else if (tier === 3) {
      results.tier3.count++;
      results.tier3.totalRewards = results.tier3.totalRewards.add(reward);
    } else {
      results.excluded.count++;
    }
  }

  // Print Distribution Summary
  console.log("\n=== Annual Distribution Summary ===");
  console.log(`\nTotal Users Analyzed: ${userActivities.length}`);
  console.log("\nDistribution by Tier:");
  console.log(`Tier 1 (Diamond Hands):
        Users: ${results.tier1.count}
        Rewards: ${ethers.utils.formatEther(
          results.tier1.totalRewards
        )} RS Options
        Avg per User: ${ethers.utils.formatEther(
          results.tier1.totalRewards.div(results.tier1.count)
        )} RS`);

  console.log(`\nTier 2 (Value Creators):
        Users: ${results.tier2.count}
        Rewards: ${ethers.utils.formatEther(
          results.tier2.totalRewards
        )} RS Options
        Avg per User: ${ethers.utils.formatEther(
          results.tier2.totalRewards.div(results.tier2.count)
        )} RS`);

  console.log(`\nTier 3 (Active Supporters):
        Users: ${results.tier3.count}
        Rewards: ${ethers.utils.formatEther(
          results.tier3.totalRewards
        )} RS Options
        Avg per User: ${ethers.utils.formatEther(
          results.tier3.totalRewards.div(results.tier3.count)
        )} RS`);

  console.log(`\nExcluded:
        Users: ${results.excluded.count}
        Percentage: ${(
          (results.excluded.count / userActivities.length) *
          100
        ).toFixed(2)}%`);

  // Calculate total distribution
  const totalDistribution = results.tier1.totalRewards
    .add(results.tier2.totalRewards)
    .add(results.tier3.totalRewards);

  console.log(
    `\nTotal RS Options to be Distributed: ${ethers.utils.formatEther(
      totalDistribution
    )}`
  );

  // Generate visual distribution
  console.log("\nDistribution Visualization:");
  console.log("Tier 1: " + "█".repeat(results.tier1.count));
  console.log("Tier 2: " + "█".repeat(results.tier2.count));
  console.log("Tier 3: " + "█".repeat(results.tier3.count));
  console.log("Excluded: " + "░".repeat(results.excluded.count));
}

// Run simulation
simulateAnnualDistribution()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
