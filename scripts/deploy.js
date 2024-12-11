const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // Deploy Token first
  const RDLToken = await ethers.getContractFactory("RDLToken");
  const token = await RDLToken.deploy(deployer.address);
  await token.deployed();
  console.log("RDLToken deployed to:", token.address);

  // Deploy MasterChef with UUPS proxy
  const MasterChef = await ethers.getContractFactory("MasterChefUpgradeable");
  const startBlock = (await ethers.provider.getBlockNumber()) + 100;
  const endBlock = startBlock + 2628000; // ~1 month of blocks

  const masterChef = await upgrades.deployProxy(
    MasterChef,
    [
      token.address,
      deployer.address, // dev address
      deployer.address, // ecosystem address
      ethers.utils.parseEther("100"), // rewards per block
      startBlock,
      endBlock,
    ],
    { kind: "uups" }
  );
  await masterChef.deployed();
  console.log("MasterChef proxy deployed to:", masterChef.address);

  // Get implementation address
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(
    masterChef.address
  );
  console.log("MasterChef implementation deployed to:", implementationAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
