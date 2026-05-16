export type SupportedChain = {
  id: number;
  name: string;
  rpcUrl: string;
  blockExplorerUrl: string;
  nativeCurrencySymbol: string;
};

export const targetChain: SupportedChain = {
  id: 84532,
  name: "Base Sepolia",
  rpcUrl: "https://sepolia.base.org",
  blockExplorerUrl: "https://sepolia.basescan.org",
  nativeCurrencySymbol: "ETH",
};

export const supportedChains: SupportedChain[] = [targetChain];
