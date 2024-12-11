interface AnnualBonus {
  baseAmount: BigNumber;
  multipliers: {
    tier1: number;
    tier2: number;
    tier3: number;
  };
  requirements: {
    minimumDays: number;
    minimumLP: BigNumber;
    minimumOptions: number;
  };
}

const ANNUAL_BONUS: AnnualBonus = {
  baseAmount: ethers.utils.parseEther("1000"), // 1000 RS
  multipliers: {
    tier1: 200, // 2x
    tier2: 150, // 1.5x
    tier3: 100, // 1x
  },
  requirements: {
    minimumDays: 180,
    minimumLP: ethers.utils.parseEther("1000"),
    minimumOptions: 5,
  },
};
