import { TokenInfo } from "./components/TokenInfo";
import { PolicyList } from "./components/PolicyList";
import { RiskTypes } from "./components/RiskTypes";
import { VaultStats } from "./components/VaultStats";
import {
  policyPreview,
  protocolContracts,
  riskTypePreview,
  tokenMetrics,
  vaultSnapshot,
} from "./lib/contracts";

export default function App() {
  return (
    <main
      style={{
        fontFamily: "Segoe UI, sans-serif",
        padding: "2rem",
        maxWidth: "1100px",
        margin: "0 auto",
      }}
    >
      <header style={{ marginBottom: "2rem" }}>
        <p style={{ textTransform: "uppercase", letterSpacing: "0.08em", color: "#5c6470" }}>
          Day 3 Dashboard Preview
        </p>
        <h1 style={{ marginBottom: "0.75rem" }}>Decentralized Insurance Pool</h1>
        <p style={{ color: "#334155", lineHeight: 1.6 }}>
          Initial read-only dashboard for frontend integration. Live wallet reads and deployed
          contract addresses will be connected in follow-up frontend PRs.
        </p>
      </header>

      <section
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
          gap: "1rem",
          marginBottom: "2rem",
        }}
      >
        {tokenMetrics.map((metric) => (
          <TokenInfo key={metric.label} metric={metric} />
        ))}
      </section>

      <section
        style={{
          display: "grid",
          gridTemplateColumns: "1.1fr 0.9fr",
          gap: "1rem",
          marginBottom: "2rem",
        }}
      >
        <VaultStats snapshot={vaultSnapshot} />
        <PolicyList policies={policyPreview} />
      </section>

      <section style={{ marginBottom: "2rem" }}>
        <RiskTypes risks={riskTypePreview} />
      </section>

      <section
        style={{
          border: "1px solid #d7dde5",
          borderRadius: "18px",
          padding: "1.25rem",
          background: "#f8fafc",
        }}
      >
        <h2 style={{ marginTop: 0 }}>Contract Config Placeholders</h2>
        <p style={{ color: "#475569", marginBottom: "1rem" }}>
          These values stay clearly marked as placeholders until the protocol is deployed.
        </p>
        <ul style={{ margin: 0, paddingLeft: "1.25rem", color: "#0f172a" }}>
          {Object.entries(protocolContracts).map(([key, value]) => (
            <li key={key}>
              <strong>{key}</strong>: {value}
            </li>
          ))}
        </ul>
      </section>
    </main>
  );
}
