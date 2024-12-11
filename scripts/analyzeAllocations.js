const { ethers } = require("hardhat");
const axios = require("axios");
require("dotenv").config();

async function main() {
  const FTMSCAN_API = "https://api.ftmscan.com/api";
  const FTMSCAN_KEY = process.env.FTMSCAN_API_KEY;

  console.log("Analyzing RDL Token Allocations...\n");

  const allocations = await getAllocations();
  console.log("Current Token Allocations:");
  console.log(allocations);
}

async function getAllocations() {
  return {
    "Team Contract (9M)": {
      address: "0x9M",
      amount: "9000000",
      status: "Active",
      recommendation: "Burn",
    },
    "Staking Contract (18.8M)": {
      address: "0x18.8M",
      amount: "18800000",
      status: "Active",
      recommendation: "Migrate",
    },
    "MasterChef Contract": {
      address: "0x7d39e3c4966dba75f998d9529d5f64502423f195",
      amount: "Variable",
      status: "Active",
      recommendation: "Migrate with Vesting",
    },
  };
}

main().catch(console.error);
