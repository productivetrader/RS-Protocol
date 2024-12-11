const { ethers, upgrades } = require("hardhat");

async function main() {
  const proxyAddress = "YOUR_PROXY_ADDRESS_HERE";

  const MasterChefV2 = await ethers.getContractFactory("MasterChefUpgradeable");
  console.log("Upgrading MasterChef...");

  await upgrades.upgradeProxy(proxyAddress, MasterChefV2);
  console.log("MasterChef upgraded");

  // Get new implementation address
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(
    proxyAddress
  );
  console.log("New implementation deployed to:", implementationAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
