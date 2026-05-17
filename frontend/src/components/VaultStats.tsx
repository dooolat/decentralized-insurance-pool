import type { CSSProperties } from "react";
import type { VaultSnapshot } from "../lib/contracts";

type VaultStatsProps = {
  snapshot: VaultSnapshot;
};

const statStyle: CSSProperties = {
  padding: "0.9rem 1rem",
  borderRadius: "14px",
  background: "#ffffff",
  border: "1px solid #d7dde5",
};

export function VaultStats({ snapshot }: VaultStatsProps) {
  return (
    <article
      style={{
        border: "1px solid #d7dde5",
        borderRadius: "18px",
        padding: "1.25rem",
        background: "#eef6ff",
      }}
    >
      <h2 style={{ marginTop: 0 }}>Vault Snapshot</h2>
      <p style={{ color: "#475569", lineHeight: 1.5 }}>
        Read-only placeholder layout for vault shares, total assets, and reserved liquidity.
      </p>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(150px, 1fr))",
          gap: "0.75rem",
        }}
      >
        <div style={statStyle}>
          <p style={{ margin: 0, color: "#64748b" }}>Vault Shares</p>
          <strong>{snapshot.shares}</strong>
        </div>
        <div style={statStyle}>
          <p style={{ margin: 0, color: "#64748b" }}>Total Assets</p>
          <strong>{snapshot.totalAssets}</strong>
        </div>
        <div style={statStyle}>
          <p style={{ margin: 0, color: "#64748b" }}>Free Liquidity</p>
          <strong>{snapshot.freeLiquidity}</strong>
        </div>
        <div style={statStyle}>
          <p style={{ margin: 0, color: "#64748b" }}>Reserved Coverage</p>
          <strong>{snapshot.reservedCoverage}</strong>
        </div>
      </div>
    </article>
  );
}
