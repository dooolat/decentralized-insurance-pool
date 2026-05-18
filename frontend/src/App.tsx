import { useMemo, useState } from "react";
import { BuyPolicyForm } from "./components/BuyPolicyForm";
import { ClaimForm } from "./components/ClaimForm";
import { DepositForm } from "./components/DepositForm";
import { PolicyList } from "./components/PolicyList";
import { RiskTypes } from "./components/RiskTypes";
import { SwapForm } from "./components/SwapForm";
import { TokenInfo } from "./components/TokenInfo";
import { VaultStats } from "./components/VaultStats";
import { VotePanel } from "./components/VotePanel";
import { WalletConnect } from "./components/WalletConnect";
import { targetChain } from "./lib/chains";
import {
  abiPlaceholders,
  contractPlaceholders,
  policyPreview,
  proposalPreview,
  riskTypePreview,
  subgraphManifestNotes,
  tokenMetrics,
  vaultSnapshot,
} from "./lib/contracts";
import { knownFrontendErrors, toReadableError } from "./lib/errors";

export default function App() {
  const [status, setStatus] = useState<string>("No protocol action submitted yet.");

  const contractSummary = useMemo(() => Object.entries(contractPlaceholders), []);

  return (
    <main
      style={{
        fontFamily: "Segoe UI, sans-serif",
        maxWidth: "1180px",
        margin: "0 auto",
        padding: "2rem",
      }}
    >
      <header style={{ marginBottom: "1.5rem" }}>
        <p style={{ textTransform: "uppercase", letterSpacing: "0.08em", color: "#64748b" }}>
          Frontend Integration UI
        </p>
        <h1 style={{ marginBottom: "0.75rem" }}>Decentralized Insurance Pool</h1>
        <p style={{ color: "#334155", lineHeight: 1.6 }}>
          This interface combines dashboard read components, governance previews, and first
          protocol action forms in one place. Base Sepolia contract addresses are filled from a
          real deployment. Governance handoff and deployment verification are complete, while
          wallet transaction handlers, live reads, and the subgraph endpoint still need final
          integration wiring.
        </p>
      </header>

      <section style={{ marginBottom: "1.5rem" }}>
        <WalletConnect
          walletName="Injected wallet"
          connectionState="wrong-network"
          targetNetwork={targetChain.name}
          helperText="Wallet connection is still shown as an integration preview. Wrong-network and connection states remain visible until live wallet actions are wired into the deployed contract addresses."
        />
      </section>

      <section
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
          gap: "1rem",
          marginBottom: "1.5rem",
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
          marginBottom: "1.5rem",
        }}
      >
        <VaultStats snapshot={vaultSnapshot} />
        <PolicyList policies={policyPreview} />
      </section>

      <section style={{ marginBottom: "1.5rem" }}>
        <RiskTypes risks={riskTypePreview} />
      </section>

      <section
        style={{
          marginBottom: "1.5rem",
          border: "1px solid #cbd5e1",
          borderRadius: "18px",
          padding: "1rem 1.25rem",
          background: "#f8fafc",
        }}
      >
        <strong>Status:</strong> {status}
      </section>

      <section
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
          gap: "1rem",
          marginBottom: "1.5rem",
        }}
      >
        <DepositForm onStatus={setStatus} />
        <BuyPolicyForm onStatus={setStatus} />
        <ClaimForm onStatus={setStatus} />
        <SwapForm onStatus={setStatus} />
        <VotePanel onStatus={setStatus} />
      </section>

      <section
        style={{
          display: "grid",
          gridTemplateColumns: "1.2fr 0.8fr",
          gap: "1rem",
          marginBottom: "1.5rem",
        }}
      >
        <article style={panelStyle}>
          <h2 style={{ marginTop: 0 }}>Contract Config</h2>
          <p style={{ color: "#475569", marginTop: 0 }}>
            These addresses come from the current Base Sepolia deployment. Governance handoff and
            deployment verification are complete, while full frontend transaction wiring is still
            pending.
          </p>
          <ul style={{ margin: 0, paddingLeft: "1.25rem" }}>
            {contractSummary.map(([key, value]) => (
              <li key={key}>
                <strong>{key}</strong>: {value}
              </li>
            ))}
          </ul>
        </article>

        <article style={panelStyle}>
          <h2 style={{ marginTop: 0 }}>Readable Error Mapping</h2>
          <ul style={{ margin: 0, paddingLeft: "1.25rem" }}>
            {knownFrontendErrors().map((message) => (
              <li key={message}>{message}</li>
            ))}
          </ul>
          <p style={{ color: "#475569", marginBottom: 0 }}>
            Example translation: <code>{toReadableError(new Error("ClaimConditionNotMet"))}</code>
          </p>
        </article>
      </section>

      <section
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))",
          gap: "1rem",
        }}
      >
        <article style={panelStyle}>
          <h2 style={{ marginTop: 0 }}>ABI Placeholders</h2>
          {Object.entries(abiPlaceholders).map(([key, value]) => (
            <div key={key} style={{ marginBottom: "0.75rem" }}>
              <strong>{key}</strong>
              <ul style={{ margin: "0.35rem 0 0", paddingLeft: "1.25rem" }}>
                {value.map((signature) => (
                  <li key={signature}>
                    <code>{signature}</code>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </article>

        <article style={panelStyle}>
          <h2 style={{ marginTop: 0 }}>Governance + Subgraph Notes</h2>
          {proposalPreview.map((proposal) => (
            <div key={proposal.id} style={listRowStyle}>
              <div>
                <strong>Proposal #{proposal.id}</strong>
                <p style={listCopyStyle}>
                  {proposal.title} | {proposal.state}
                </p>
              </div>
            </div>
          ))}
          <p style={{ color: "#475569", marginBottom: 0 }}>
            Subgraph network: <strong>{subgraphManifestNotes.network}</strong> | Deployment:{" "}
            <strong>{subgraphManifestNotes.deployment}</strong>
          </p>
        </article>
      </section>
    </main>
  );
}

const panelStyle = {
  border: "1px solid #d7dde5",
  borderRadius: "18px",
  padding: "1rem 1.25rem",
  background: "#ffffff",
};

const listRowStyle = {
  padding: "0.65rem 0",
  borderBottom: "1px solid #e2e8f0",
};

const listCopyStyle = {
  color: "#475569",
  margin: "0.25rem 0 0",
};
