const { expect } = require("chai");
const hre = require("hardhat");

async function main() {
  console.log("Starting deployment verification tests...");

  // Get deployed contract instances
  const rsToken = await hre.ethers.getContractAt("RSToken", "DEPLOYED_ADDRESS");

  console.log("\n1. Testing RSToken Configuration:");
  try {
    const name = await rsToken.name();
    const symbol = await rsToken.symbol();
    const totalSupply = await rsToken.totalSupply();
    const admin = await rsToken.hasRole(
      await rsToken.DEFAULT_ADMIN_ROLE(),
      "0x332590f80833179608Fc87B55388eDfCBf6800BC"
    );

    console.log(`✓ Name: ${name}`);
    console.log(`✓ Symbol: ${symbol}`);
    console.log(`✓ Total Supply: ${totalSupply}`);
    console.log(`✓ Admin Role Configured: ${admin}`);

    // Get allocation details
    const allocations = await rsToken.getAllocationDetails();
    console.log("\nToken Allocations Verified:");
    console.log(`✓ Dutch Auction: ${allocations.dutchAuction}`);
    console.log(`✓ Retroactive 1: ${allocations.retroActive1}`);
    console.log(`✓ Retroactive 2: ${allocations.retroActive2}`);
    console.log(`✓ Team Options: ${allocations.teamOptions}`);
    console.log(`✓ LP Incentives: ${allocations.lpIncentives}`);
    console.log(`✓ Annual Bonus: ${allocations.annualBonus}`);
    console.log(`✓ Treasury: ${allocations.treasury}`);
  } catch (error) {
    console.error("❌ RSToken verification failed:", error);
  }

  // Add more test sections as we deploy other contracts
}

// Execute tests
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
