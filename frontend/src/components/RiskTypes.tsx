import type { RiskTypePreview } from "../lib/contracts";

type RiskTypesProps = {
  risks: RiskTypePreview[];
};

export function RiskTypes({ risks }: RiskTypesProps) {
  return (
    <article
      style={{
        border: "1px solid #d7dde5",
        borderRadius: "18px",
        padding: "1.25rem",
        background: "#ffffff",
      }}
    >
      <h2 style={{ marginTop: 0 }}>Accepted Risk Types</h2>
      <p style={{ color: "#475569", lineHeight: 1.5 }}>
        Initial UI for registry reads. Real values will come from `RiskRegistry.getRiskType`
        once the frontend wiring is added.
      </p>
      <div style={{ display: "grid", gap: "0.9rem" }}>
        {risks.map((risk) => (
          <div
            key={risk.id}
            style={{
              border: "1px solid #e2e8f0",
              borderRadius: "14px",
              padding: "1rem",
              background: risk.active ? "#f8fafc" : "#fff7ed",
            }}
          >
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                gap: "1rem",
                marginBottom: "0.4rem",
              }}
            >
              <strong>{risk.name}</strong>
              <span style={{ color: risk.active ? "#166534" : "#9a3412" }}>
                {risk.active ? "Active" : "Inactive"}
              </span>
            </div>
            <p style={{ margin: "0.2rem 0", color: "#475569" }}>
              Premium rate: {risk.premiumRateBps} bps
            </p>
            <p style={{ margin: "0.2rem 0", color: "#475569" }}>
              Max coverage: {risk.maxCoverage}
            </p>
            <p style={{ margin: "0.2rem 0", color: "#475569" }}>
              Trigger threshold: {risk.triggerThreshold}
            </p>
          </div>
        ))}
      </div>
    </article>
  );
}
