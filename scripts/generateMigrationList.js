const axios = require("axios");
require("dotenv").config();

async function generateMigrationList() {
  console.log("Generating comprehensive RDL migration list...\n");

  const categories = {
    TIER_1: {
      description: "Loyal Holders & Productive Traders",
      criteria: "1:1 migration",
      subCategories: {
        DIAMOND_HANDS: "Never sold, bought low",
        SMART_TRADER: "Strategic sells/rebuys, increased position",
        LONG_TERM: "Held >75% of tokens through cycles",
      },
    },
    TIER_2: {
      description: "Positive Contributors with Some Selling",
      criteria: "0.8:1 migration",
      subCategories: {
        PARTIAL_SELLER: "Sold <50% at high prices, still holding",
        ACTIVE_TRADER: "Multiple trades but maintained position",
      },
    },
    EXCLUDED: {
      description: "Protocol Damaging Behavior",
      criteria: "No migration",
      subCategories: {
        DUMPERS: "Sold >90% at peak",
        REWARD_ABUSERS: "Farmed and dumped rewards",
        BOTS: "Automated exploitation",
        SUSPICIOUS: "Manipulation patterns",
      },
    },
  };

  try {
    const holders = await analyzeAllHolders();
    console.log("\nFinal Migration List:");

    // TIER 1 Analysis
    console.log("\nTIER 1 - Full Migration Rights:");
    const tier1 = holders.filter(
      (h) =>
        (h.neverSold || h.productiveTrading) &&
        h.currentHolding > h.originalPosition
    );

    // TIER 2 Analysis
    console.log("\nTIER 2 - Partial Migration Rights:");
    const tier2 = holders.filter(
      (h) => h.soldPercentage < 50 && h.rebought && h.currentHolding > 0
    );

    // EXCLUDED Analysis
    console.log("\nEXCLUDED - No Migration Rights:");
    const excluded = holders.filter(
      (h) => h.dumperPattern || h.botActivity || h.rewardAbuse
    );

    // Generate final statistics
    console.log("\nFinal Statistics:");
    console.log(`Total Addresses Analyzed: ${holders.length}`);
    console.log(`TIER 1 Addresses: ${tier1.length}`);
    console.log(`TIER 2 Addresses: ${tier2.length}`);
    console.log(`Excluded Addresses: ${excluded.length}`);

    // Calculate total RDL eligible for migration
    const totalEligibleRDL = calculateEligibleRDL(tier1, tier2);
    console.log(`\nTotal RDL Eligible for Migration: ${totalEligibleRDL}`);
  } catch (error) {
    console.error("Error generating migration list:", error);
  }
}

// Would you like me to run this comprehensive analysis now? yes
