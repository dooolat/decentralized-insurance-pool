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

export const contractPlaceholders = {
  collateralToken: "TBD_AFTER_DEPLOYMENT",
  governanceToken: "TBD_AFTER_DEPLOYMENT",
  policyNft: "TBD_AFTER_DEPLOYMENT",
  insuranceVault: "TBD_AFTER_DEPLOYMENT",
  riskRegistry: "TBD_AFTER_DEPLOYMENT",
  insurancePool: "TBD_AFTER_DEPLOYMENT",
  claimManager: "TBD_AFTER_DEPLOYMENT",
  insuranceAmm: "TBD_AFTER_DEPLOYMENT",
  protocolGovernor: "TBD_AFTER_DEPLOYMENT",
  protocolTimelock: "TBD_AFTER_DEPLOYMENT",
} as const;

export const protocolContracts = contractPlaceholders;

export const abiPlaceholders = {
  governanceToken: ["delegate(address)", "getVotes(address)"],
  policyNft: ["ownerOf(uint256)", "tokenURI(uint256)"],
  insuranceVault: [
    "deposit(uint256 assets, address receiver)",
    "withdraw(uint256 assets, address receiver, address owner)",
  ],
  riskRegistry: ["getRiskType(uint256)", "deactivateRiskType(uint256)"],
  insurancePool: [
    "buyPolicy(uint256 riskTypeId, uint256 coverageAmount, uint256 duration)",
    "getPolicy(uint256 policyId)",
  ],
  claimManager: ["executeClaim(uint256 policyId)"],
  insuranceAmm: [
    "swapExactInput(address tokenIn, uint256 amountIn, uint256 minAmountOut, address recipient)",
  ],
  protocolGovernor: ["castVote(uint256 proposalId, uint8 support)"],
  protocolTimelock: ["schedule(bytes32 id)", "execute(bytes32 id)"],
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
  {
    label: "Claimable Policies",
    value: "0",
    helper: "Placeholder summary for policies that satisfy a claim trigger.",
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

export const riskTypeOptions = riskTypePreview.map((risk) => ({
  id: risk.id,
  name: risk.name,
  premiumRateBps: risk.premiumRateBps,
  status: risk.active ? "active preview until onchain registry reads are wired" : "inactive preview",
})) as const;

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

export const proposalPreview = [
  {
    id: "1",
    title: "Activate first risk type",
    state: "Preview",
    note: "Replace with live governance proposals after deployment.",
  },
  {
    id: "2",
    title: "Tune vault reserve floor",
    state: "Queued preview",
    note: "Displayed as a UI example until Governor events are indexed.",
  },
] as const;

export const subgraphManifestNotes = {
  network: "base-sepolia",
  deployment: "not deployed yet",
  endpoint: "set after real Graph deployment",
} as const;
