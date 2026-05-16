import type { DashboardMetric } from "../lib/contracts";

type TokenInfoProps = {
  metric: DashboardMetric;
};

export function TokenInfo({ metric }: TokenInfoProps) {
  return (
    <article
      style={{
        border: "1px solid #d7dde5",
        borderRadius: "18px",
        padding: "1.25rem",
        background: "#ffffff",
        boxShadow: "0 10px 30px rgba(15, 23, 42, 0.05)",
      }}
    >
      <p style={{ margin: 0, color: "#64748b", fontSize: "0.9rem" }}>{metric.label}</p>
      <strong style={{ display: "block", fontSize: "1.8rem", margin: "0.5rem 0", color: "#0f172a" }}>
        {metric.value}
      </strong>
      <p style={{ margin: 0, color: "#475569", lineHeight: 1.5 }}>{metric.helper}</p>
    </article>
  );
}
