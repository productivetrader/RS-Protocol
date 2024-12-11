require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

const SONIC_PRIVATE_KEY = process.env.SONIC_PRIVATE_KEY;

module.exports = {
  solidity: {
    version: "0.8.26",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    sonictest: {
      url: "https://rpc.blaze.soniclabs.com",
      accounts: [SONIC_PRIVATE_KEY],
      chainId: 57054, // Sonic Blaze Testnet (0xdede)
    },
    sonicmain: {
      url: "https://rpc.soniclabs.com",
      accounts: [SONIC_PRIVATE_KEY],
      chainId: 146, // Sonic Mainnet (0x92)
    },
  },
};
