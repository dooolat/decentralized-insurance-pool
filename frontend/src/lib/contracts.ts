export const contractPlaceholders = {
    collateralToken: "set via VITE_COLLATERAL_TOKEN_ADDRESS",
    governanceToken: "set via VITE_GOVERNANCE_TOKEN_ADDRESS",
    insuranceVault: "set via VITE_INSURANCE_VAULT_ADDRESS",
    insurancePool: "set via VITE_INSURANCE_POOL_ADDRESS",
    claimManager: "set via VITE_CLAIM_MANAGER_ADDRESS",
    insuranceAmm: "set via VITE_INSURANCE_AMM_ADDRESS",
    protocolGovernor: "set via VITE_PROTOCOL_GOVERNOR_ADDRESS"
} as const;

export const abiPlaceholders = {
    insuranceVault: [
        "deposit(uint256 assets, address receiver)",
        "withdraw(uint256 assets, address receiver, address owner)"
    ],
    insurancePool: [
        "buyPolicy(uint256 riskTypeId, uint256 coverageAmount, uint256 duration)",
        "getActivePolicies()"
    ],
    claimManager: [
        "executeClaim(uint256 policyId)"
    ],
    insuranceAmm: [
        "swapExactInput(address tokenIn, uint256 amountIn, uint256 minAmountOut, address recipient)"
    ],
    protocolGovernor: [
        "castVote(uint256 proposalId, uint8 support)"
    ]
} as const;

export const riskTypeOptions = [
    {
        id: 1,
        name: "STABLECOIN_DEPEG",
        premiumRateBps: 250,
        status: "placeholder until registry is read onchain"
    },
    {
        id: 2,
        name: "ASSET_PRICE_DROP",
        premiumRateBps: 400,
        status: "placeholder until registry is read onchain"
    }
] as const;

export const proposalPreview = [
    {
        id: "1",
        title: "Activate first risk type",
        state: "Placeholder",
        note: "Replace with live governance proposals after deploy."
    }
] as const;

export const subgraphManifestNotes = {
    network: "base-sepolia",
    deployment: "not deployed yet",
    endpoint: "set after real Graph deployment"
} as const;
