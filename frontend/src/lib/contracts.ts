export type ContractBootstrap = {
  key: string;
  label: string;
  address: string;
  abiPreview: string[];
  notes: string;
};

export const contractRegistry: ContractBootstrap[] = [
  {
    key: "governanceToken",
    label: "GovernanceToken",
    address: "TBD_AFTER_DEPLOYMENT",
    abiPreview: ["delegate(address)", "getVotes(address)"],
    notes: "Governor-compatible voting token placeholder for later integration.",
  },
  {
    key: "policyNft",
    label: "PolicyNFT",
    address: "TBD_AFTER_DEPLOYMENT",
    abiPreview: ["ownerOf(uint256)", "tokenURI(uint256)"],
    notes: "Policy ownership read paths will be wired in a later dashboard PR.",
  },
  {
    key: "insuranceVault",
    label: "InsuranceVault",
    address: "TBD_AFTER_DEPLOYMENT",
    abiPreview: ["deposit(uint256,address)", "withdraw(uint256,address,address)"],
    notes: "Vault actions depend on the next protocol action milestone.",
  },
  {
    key: "insurancePool",
    label: "InsurancePool",
    address: "TBD_AFTER_DEPLOYMENT",
    abiPreview: ["buyPolicy(uint256,uint256,uint256)", "getActivePolicies()"],
    notes: "Policy purchase and status reads will be connected after deployment work.",
  },
];
