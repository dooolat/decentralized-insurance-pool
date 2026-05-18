import { baseSepolia } from "wagmi/chains";
import { parseAbi } from "viem";

export const TARGET_CHAIN = baseSepolia;

export const addresses = {
  collateralToken: import.meta.env.VITE_COLLATERAL_TOKEN_ADDRESS as `0x${string}` | undefined,
  governanceToken: import.meta.env.VITE_GOVERNANCE_TOKEN_ADDRESS as `0x${string}` | undefined,
  policyNft: import.meta.env.VITE_POLICY_NFT_ADDRESS as `0x${string}` | undefined,
  insuranceVault: import.meta.env.VITE_INSURANCE_VAULT_ADDRESS as `0x${string}` | undefined,
  riskRegistry: import.meta.env.VITE_RISK_REGISTRY_ADDRESS as `0x${string}` | undefined,
  insurancePool: import.meta.env.VITE_INSURANCE_POOL_ADDRESS as `0x${string}` | undefined,
  claimManager: import.meta.env.VITE_CLAIM_MANAGER_ADDRESS as `0x${string}` | undefined,
  insuranceAmm: import.meta.env.VITE_INSURANCE_AMM_ADDRESS as `0x${string}` | undefined,
  protocolGovernor: import.meta.env.VITE_PROTOCOL_GOVERNOR_ADDRESS as `0x${string}` | undefined,
  protocolTimelock: import.meta.env.VITE_PROTOCOL_TIMELOCK_ADDRESS as `0x${string}` | undefined,
} as const;

export const subgraphUrl = import.meta.env.VITE_SUBGRAPH_URL as string | undefined;
export const walletConnectProjectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID as
  | string
  | undefined;

export const erc20Abi = parseAbi([
  "function balanceOf(address account) view returns (uint256)",
  "function allowance(address owner, address spender) view returns (uint256)",
  "function approve(address spender, uint256 amount) returns (bool)",
  "function decimals() view returns (uint8)",
  "function symbol() view returns (string)",
]);

export const governanceTokenAbi = parseAbi([
  "function balanceOf(address account) view returns (uint256)",
  "function delegates(address account) view returns (address)",
  "function getVotes(address account) view returns (uint256)",
  "function delegate(address delegatee)",
]);

export const vaultAbi = parseAbi([
  "function balanceOf(address account) view returns (uint256)",
  "function totalAssets() view returns (uint256)",
  "function maxWithdraw(address owner) view returns (uint256)",
  "function deposit(uint256 assets, address receiver) returns (uint256)",
  "function withdraw(uint256 assets, address receiver, address owner) returns (uint256)",
]);

export const riskRegistryAbi = parseAbi([
  "function riskTypeCount() view returns (uint256)",
  "function getRiskType(uint256 riskTypeId) view returns (string name, uint16 premiumRateBps, uint256 maxCoverage, address oracleFeed, uint256 triggerThreshold, uint256 stalenessLimit, bool active)",
]);

export const insurancePoolAbi = parseAbi([
  "function getActivePolicies() view returns ((uint256 policyId, address buyer, uint256 riskTypeId, uint256 premium, uint256 coverageAmount, uint256 startTime, uint256 endTime, uint8 status)[])",
  "function nextPolicyId() view returns (uint256)",
  "function buyPolicy(uint256 riskTypeId, uint256 coverageAmount, uint256 duration) returns (uint256)",
]);

export const policyNftAbi = parseAbi([
  "function ownerOf(uint256 tokenId) view returns (address)",
  "function tokenURI(uint256 tokenId) view returns (string)",
]);

export const claimManagerAbi = parseAbi([
  "function executeClaim(uint256 policyId) returns (bool paid, uint256 payoutAmount)",
]);

export const insuranceAmmAbi = parseAbi([
  "function getReserves() view returns (uint112 reserve0, uint112 reserve1)",
  "function swapExactInput(address tokenIn, uint256 amountIn, uint256 minAmountOut, address recipient) returns (uint256)",
]);

export const governorAbi = parseAbi([
  "function castVote(uint256 proposalId, uint8 support) returns (uint256)",
]);

export function hasCoreAddresses(): boolean {
  return Boolean(
    addresses.collateralToken &&
      addresses.governanceToken &&
      addresses.policyNft &&
      addresses.insuranceVault &&
      addresses.riskRegistry &&
      addresses.insurancePool &&
      addresses.claimManager &&
      addresses.insuranceAmm &&
      addresses.protocolGovernor
  );
}
