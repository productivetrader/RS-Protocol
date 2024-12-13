const { expect } = require("chai");
const hre = require("hardhat");

async function main() {
  console.log("Testing Analytics and Treasury Systems...");

  // Test Analytics Scoring
  async function testAnalytics() {
    console.log("\nTesting Analytics System:");
    const analytics = await hre.ethers.getContractAt(
      "RSAnalytics",
      "DEPLOYED_ADDRESS"
    );

    try {
      // Test scoring components
      const testAddress = "0x332590f80833179608Fc87B55388eDfCBf6800BC";

      console.log("Testing Score Calculations:");
      const lpScore = await analytics.calculateLPScore(testAddress);
      console.log(`✓ LP Score: ${lpScore}`);

      const optionsScore = await analytics.calculateOptionsScore(testAddress);
      console.log(`✓ Options Score: ${optionsScore}`);

      const tradingScore = await analytics.calculateTradingScore(testAddress);
      console.log(`✓ Trading Score: ${tradingScore}`);

      const contributionScore = await analytics.calculateContributionScore(
        testAddress
      );
      console.log(`✓ Contribution Score: ${contributionScore}`);

      // Test tier calculation
      await analytics.updateUserScore(testAddress);
      const userTier = await analytics.getUserTier(testAddress);
      console.log(`✓ User Tier Calculated: ${userTier}`);
    } catch (error) {
      console.error("❌ Analytics test failed:", error);
    }
  }

  // Test Distribution Tracker
  async function testDistributionTracker() {
    console.log("\nTesting Distribution Tracker:");
    const tracker = await hre.ethers.getContractAt(
      "RSDistributionTracker",
      "DEPLOYED_ADDRESS"
    );

    try {
      // Test phase tracking
      const firstRetroPhase = await tracker.getPhaseStatus(0); // FIRST_RETRO
      console.log("Phase Status Check:");
      console.log(`✓ First Retro Active: ${firstRetroPhase.isActive}`);
      console.log(`✓ Allocated Amount: ${firstRetroPhase.allocated}`);

      // Test distribution recording
      const remainingAllocation = await tracker.getRemainingAllocation(0);
      console.log(`✓ Remaining Allocation: ${remainingAllocation}`);
    } catch (error) {
      console.error("❌ Distribution Tracker test failed:", error);
    }
  }

  // Test MasterChef
  async function testMasterChef() {
    console.log("\nTesting MasterChef:");
    const masterChef = await hre.ethers.getContractAt(
      "RSMasterChef",
      "DEPLOYED_ADDRESS"
    );

    try {
      // Test pool management
      const poolLength = await masterChef.poolInfo.length;
      console.log(`✓ Number of Pools: ${poolLength}`);

      // Test reward calculations
      const rewardPerSecond = await masterChef.rewardPerSecond();
      console.log(`✓ Reward Rate: ${rewardPerSecond}`);
    } catch (error) {
      console.error("❌ MasterChef test failed:", error);
    }
  }

  // Test Treasury
  async function testTreasury() {
    console.log("\nTesting Treasury:");
    const treasury = await hre.ethers.getContractAt(
      "RSTreasury",
      "DEPLOYED_ADDRESS"
    );

    try {
      // Test treasury allocation
      const hasAdminRole = await treasury.hasRole(
        await treasury.TREASURY_ADMIN(),
        "0x332590f80833179608Fc87B55388eDfCBf6800BC"
      );
      console.log(`✓ Admin Role Configured: ${hasAdminRole}`);

      // Test spending tracking
      const spendingHistory = await treasury.spendingHistory(0);
      console.log("✓ Spending History Accessible");
    } catch (error) {
      console.error("❌ Treasury test failed:", error);
    }
  }

  // Execute all tests
  await testAnalytics();
  await testDistributionTracker();
  await testMasterChef();
  await testTreasury();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
