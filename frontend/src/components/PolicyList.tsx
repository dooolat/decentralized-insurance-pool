import type { PolicyPreview } from "../lib/contracts";

type PolicyListProps = {
  policies: PolicyPreview[];
};

export function PolicyList({ policies }: PolicyListProps) {
  return (
    <article
      style={{
        border: "1px solid #d7dde5",
        borderRadius: "18px",
        padding: "1.25rem",
        background: "#fffdf7",
      }}
    >
      <h2 style={{ marginTop: 0 }}>User Policies</h2>
      <p style={{ color: "#475569", lineHeight: 1.5 }}>
        Placeholder list for active policies owned by the connected wallet.
      </p>
      <div style={{ display: "grid", gap: "0.85rem" }}>
        {policies.map((policy) => (
          <div
            key={policy.policyId}
            style={{
              border: "1px solid #e2e8f0",
              borderRadius: "14px",
              padding: "1rem",
              background: "#ffffff",
            }}
          >
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                gap: "1rem",
              }}
            >
              <strong>Policy #{policy.policyId}</strong>
              <span>{policy.status}</span>
            </div>
            <p style={{ margin: "0.35rem 0", color: "#475569" }}>Coverage: {policy.coverage}</p>
            <p style={{ margin: "0.35rem 0", color: "#475569" }}>Premium: {policy.premium}</p>
            <p style={{ margin: "0.35rem 0", color: "#475569" }}>Buyer: {policy.buyer}</p>
          </div>
        ))}
      </div>
    </article>
  );
}
