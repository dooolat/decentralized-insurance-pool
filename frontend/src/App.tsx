import { WalletConnect } from "./components/WalletConnect";
import { supportedChains, targetChain } from "./lib/chains";
import { contractRegistry } from "./lib/contracts";

const cardStyle = {
  background: "#ffffff",
  border: "1px solid #e5e7eb",
  borderRadius: "18px",
  padding: "18px",
} as const;

export default function App() {
  return (
    <main
      style={{
        background: "linear-gradient(180deg, #f8fafc 0%, #ffffff 100%)",
        color: "#0f172a",
        fontFamily: "Arial, sans-serif",
        margin: "0 auto",
        maxWidth: "1080px",
        minHeight: "100vh",
        padding: "40px 20px 64px",
      }}
    >
      <section style={{ marginBottom: "28px" }}>
        <p style={{ color: "#475569", fontSize: "14px", margin: "0 0 10px" }}>
          Option E • Decentralized Insurance Pool
        </p>
        <h1 style={{ fontSize: "40px", lineHeight: 1.1, margin: "0 0 14px" }}>
          Wallet bootstrap for the insurance protocol dashboard
        </h1>
        <p style={{ color: "#334155", fontSize: "18px", lineHeight: 1.6, margin: 0 }}>
          This Day 2 frontend milestone adds the initial wallet connection layout, target network
          configuration, and basic contract registry placeholders for later protocol reads and
          writes.
        </p>
      </section>

      <WalletConnect
        walletName="MetaMask / WalletConnect"
        connectionState="disconnected"
        targetNetwork={targetChain.name}
        helperText="Interactive connect and switch actions will be wired in the next frontend PR."
      />

      <section
        style={{
          display: "grid",
          gap: "18px",
          gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
          margin: "28px 0",
        }}
      >
        <article style={cardStyle}>
          <p style={{ color: "#64748b", fontSize: "13px", margin: "0 0 8px" }}>Target chain</p>
          <strong>{targetChain.name}</strong>
        </article>
        <article style={cardStyle}>
          <p style={{ color: "#64748b", fontSize: "13px", margin: "0 0 8px" }}>Chain ID</p>
          <strong>{targetChain.id}</strong>
        </article>
        <article style={cardStyle}>
          <p style={{ color: "#64748b", fontSize: "13px", margin: "0 0 8px" }}>
            Supported networks
          </p>
          <strong>{supportedChains.length}</strong>
        </article>
        <article style={cardStyle}>
          <p style={{ color: "#64748b", fontSize: "13px", margin: "0 0 8px" }}>
            Contract placeholders
          </p>
          <strong>{contractRegistry.length}</strong>
        </article>
      </section>

      <section style={{ ...cardStyle, marginBottom: "18px" }}>
        <h2 style={{ fontSize: "24px", margin: "0 0 14px" }}>Network configuration</h2>
        <p style={{ color: "#334155", lineHeight: 1.6, margin: "0 0 10px" }}>
          The frontend is currently prepared for a Base Sepolia deployment target. Real contract
          addresses will be filled after testnet deployment.
        </p>
        <ul style={{ color: "#334155", lineHeight: 1.8, margin: 0, paddingLeft: "18px" }}>
          <li>RPC URL: {targetChain.rpcUrl}</li>
          <li>Explorer: {targetChain.blockExplorerUrl}</li>
          <li>Native token: {targetChain.nativeCurrencySymbol}</li>
        </ul>
      </section>

      <section style={cardStyle}>
        <h2 style={{ fontSize: "24px", margin: "0 0 14px" }}>Contract registry scaffold</h2>
        <div style={{ display: "grid", gap: "12px" }}>
          {contractRegistry.map((contract) => (
            <article
              key={contract.key}
              style={{
                background: "#f8fafc",
                borderRadius: "14px",
                padding: "14px 16px",
              }}
            >
              <div
                style={{
                  alignItems: "center",
                  display: "flex",
                  justifyContent: "space-between",
                  marginBottom: "8px",
                }}
              >
                <strong>{contract.label}</strong>
                <code style={{ color: "#64748b" }}>{contract.address}</code>
              </div>
              <p style={{ color: "#334155", margin: "0 0 8px" }}>{contract.notes}</p>
              <code style={{ color: "#0f172a", fontSize: "13px" }}>
                {contract.abiPreview.join(" | ")}
              </code>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
