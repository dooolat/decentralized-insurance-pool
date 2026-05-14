export type DashboardMetric = {
  label: string;
  value: string;
  helper: string;
};

export type VaultSnapshot = {
  shares: string;
  totalAssets: string;
  freeLiquidity: string;
  reservedCoverage: string;
};

export type RiskTypePreview = {
  id: number;
  name: string;
  premiumRateBps: number;
  maxCoverage: string;
  triggerThreshold: string;
  active: boolean;
};

export type PolicyPreview = {
  policyId: number;
  buyer: string;
  coverage: string;
  premium: string;
  status: string;
};

export const protocolContracts = {
  governanceToken: "<set-after-deploy>",
  policyNft: "<set-after-deploy>",
  insuranceVault: "<set-after-deploy>",
  riskRegistry: "<set-after-deploy>",
  insurancePool: "<set-after-deploy>",
} as const;

export const tokenMetrics: DashboardMetric[] = [
  {
    label: "Collateral Token Balance",
    value: "0.00 USDC",
    helper: "Placeholder card for the connected user's collateral balance.",
  },
  {
    label: "Governance Voting Power",
    value: "0.00 IGOV",
    helper: "Placeholder card for delegated voting power once Governor reads are connected.",
  },
];

export const vaultSnapshot: VaultSnapshot = {
  shares: "0.00 IVS",
  totalAssets: "0.00 USDC",
  freeLiquidity: "0.00 USDC",
  reservedCoverage: "0.00 USDC",
};

export const riskTypePreview: RiskTypePreview[] = [
  {
    id: 1,
    name: "STABLECOIN_DEPEG",
    premiumRateBps: 180,
    maxCoverage: "100,000 USDC",
    triggerThreshold: "0.97 USD",
    active: true,
  },
  {
    id: 2,
    name: "ASSET_PRICE_DROP",
    premiumRateBps: 240,
    maxCoverage: "250,000 USDC",
    triggerThreshold: "85% TWAP",
    active: true,
  },
  {
    id: 3,
    name: "LIQUIDATION_EVENT",
    premiumRateBps: 120,
    maxCoverage: "75,000 USDC",
    triggerThreshold: "Protocol-defined event",
    active: false,
  },
];

export const policyPreview: PolicyPreview[] = [
  {
    policyId: 7,
    buyer: "0xBuyer...1234",
    coverage: "1,000 USDC",
    premium: "24 USDC",
    status: "Active",
  },
  {
    policyId: 8,
    buyer: "0xBuyer...1234",
    coverage: "2,500 USDC",
    premium: "52 USDC",
    status: "Placeholder",
  },
];
