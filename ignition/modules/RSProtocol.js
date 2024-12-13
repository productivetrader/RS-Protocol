const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const ADMIN_ADDRESS = "0x332590f80833179608Fc87B55388eDfCBf6800BC";

module.exports = buildModule("RSProtocolModule", async (m) => {
  // Deploy RS Token first
  const rsToken = m.contract("RSToken", [
    "Radial Sonic Token",
    "RS",
    ADMIN_ADDRESS,
  ]);

  // Deploy analytics and tracking (these don't require token addresses)
  const analytics = m.contract("RSAnalytics", [ADMIN_ADDRESS]);
  const distributionTracker = m.contract("RSDistributionTracker");
  const treasury = m.contract("RSTreasury", [rsToken.address]);

  console.log("Deployment addresses:");
  console.log("RSToken:", rsToken.address);
  console.log("Analytics:", analytics.address);
  console.log("DistributionTracker:", distributionTracker.address);
  console.log("Treasury:", treasury.address);

  return {
    rsToken,
    analytics,
    distributionTracker,
    treasury,
  };
});
