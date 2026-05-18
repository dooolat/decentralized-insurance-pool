import { createConfig, http } from "wagmi";
import { metaMask, walletConnect } from "wagmi/connectors";
import { baseSepolia } from "wagmi/chains";
import { walletConnectProjectId } from "./contracts";

const connectors = walletConnectProjectId
  ? [
      metaMask(),
      walletConnect({
        projectId: walletConnectProjectId,
        showQrModal: true,
      }),
    ]
  : [metaMask()];

export const wagmiConfig = createConfig({
  chains: [baseSepolia],
  connectors,
  transports: {
    [baseSepolia.id]: http(import.meta.env.VITE_BASE_SEPOLIA_RPC_URL),
  },
});
