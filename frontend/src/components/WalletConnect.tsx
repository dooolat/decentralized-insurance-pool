type WalletConnectProps = {
  walletName: string;
  connectionState: "disconnected" | "connecting" | "connected" | "wrong-network";
  targetNetwork: string;
  helperText: string;
};

const statePalette: Record<
  WalletConnectProps["connectionState"],
  { background: string; label: string }
> = {
  disconnected: { background: "#94a3b8", label: "Disconnected" },
  connecting: { background: "#f59e0b", label: "Connecting" },
  connected: { background: "#10b981", label: "Connected" },
  "wrong-network": { background: "#ef4444", label: "Wrong network" },
};

export function WalletConnect({
  walletName,
  connectionState,
  targetNetwork,
  helperText,
}: WalletConnectProps) {
  const state = statePalette[connectionState];

  return (
    <section
      style={{
        background: "#ffffff",
        border: "1px solid #e5e7eb",
        borderRadius: "22px",
        padding: "24px",
      }}
    >
      <div
        style={{
          alignItems: "center",
          display: "flex",
          flexWrap: "wrap",
          gap: "14px",
          justifyContent: "space-between",
          marginBottom: "16px",
        }}
      >
        <div>
          <p style={{ color: "#64748b", fontSize: "13px", margin: "0 0 8px" }}>Wallet status</p>
          <h2 style={{ fontSize: "28px", margin: 0 }}>{walletName}</h2>
        </div>
        <span
          style={{
            background: state.background,
            borderRadius: "999px",
            color: "#ffffff",
            display: "inline-block",
            fontSize: "13px",
            padding: "8px 14px",
          }}
        >
          {state.label}
        </span>
      </div>

      <div
        style={{
          display: "grid",
          gap: "12px",
          gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
          marginBottom: "18px",
        }}
      >
        <div style={{ background: "#f8fafc", borderRadius: "14px", padding: "16px" }}>
          <p style={{ color: "#64748b", fontSize: "13px", margin: "0 0 8px" }}>Target network</p>
          <strong>{targetNetwork}</strong>
        </div>
        <div style={{ background: "#f8fafc", borderRadius: "14px", padding: "16px" }}>
          <p style={{ color: "#64748b", fontSize: "13px", margin: "0 0 8px" }}>Current flow</p>
          <strong>Bootstrap UI only</strong>
        </div>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: "12px", marginBottom: "12px" }}>
        <button
          disabled
          style={{
            background: "#111827",
            border: "none",
            borderRadius: "12px",
            color: "#ffffff",
            cursor: "not-allowed",
            padding: "12px 18px",
          }}
        >
          Connect wallet
        </button>
        <button
          disabled
          style={{
            background: "#ffffff",
            border: "1px solid #cbd5e1",
            borderRadius: "12px",
            color: "#0f172a",
            cursor: "not-allowed",
            padding: "12px 18px",
          }}
        >
          Switch network
        </button>
      </div>

      <p style={{ color: "#334155", lineHeight: 1.6, margin: 0 }}>{helperText}</p>
    </section>
  );
}
