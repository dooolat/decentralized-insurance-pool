import { useState } from "react";
import { contractPlaceholders } from "../lib/contracts";

type Props = {
    onStatus: (message: string) => void;
};

export function DepositForm({ onStatus }: Props) {
    const [amount, setAmount] = useState("100");

    return (
        <section style={panelStyle}>
            <h2 style={headingStyle}>Deposit To Vault</h2>
            <p style={copyStyle}>
                Target contract: <code>{contractPlaceholders.insuranceVault}</code>
            </p>
            <label style={labelStyle}>
                Collateral amount
                <input
                    style={inputStyle}
                    value={amount}
                    onChange={(event) => setAmount(event.target.value)}
                    placeholder="100.0"
                />
            </label>
            <button
                style={buttonStyle}
                type="button"
                onClick={() =>
                    onStatus(`Prepared vault deposit preview for ${amount} collateral.`)
                }
            >
                Prepare deposit action
            </button>
        </section>
    );
}

const panelStyle = {
    border: "1px solid #d7dde5",
    borderRadius: "16px",
    padding: "1rem",
    background: "#ffffff"
};

const headingStyle = {
    marginTop: 0,
    marginBottom: "0.5rem"
};

const copyStyle = {
    color: "#475569",
    marginTop: 0,
    marginBottom: "0.75rem"
};

const labelStyle = {
    display: "grid",
    gap: "0.4rem",
    color: "#0f172a",
    marginBottom: "0.75rem"
};

const inputStyle = {
    border: "1px solid #cbd5e1",
    borderRadius: "10px",
    padding: "0.7rem 0.8rem"
};

const buttonStyle = {
    border: "none",
    borderRadius: "999px",
    padding: "0.75rem 1rem",
    background: "#0f766e",
    color: "#ffffff",
    cursor: "pointer"
};
