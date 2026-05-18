import { useState } from "react";
import { contractPlaceholders } from "../lib/contracts";

type Props = {
    onStatus: (message: string) => void;
};

export function ClaimForm({ onStatus }: Props) {
    const [policyId, setPolicyId] = useState("1");

    return (
        <section style={panelStyle}>
            <h2 style={headingStyle}>Execute Claim</h2>
            <p style={copyStyle}>
                Claims are routed through <code>{contractPlaceholders.claimManager}</code>.
            </p>
            <label style={labelStyle}>
                Policy ID
                <input
                    style={inputStyle}
                    value={policyId}
                    onChange={(event) => setPolicyId(event.target.value)}
                />
            </label>
            <button
                style={buttonStyle}
                type="button"
                onClick={() => onStatus(`Prepared claim execution preview for policy #${policyId}.`)}
            >
                Prepare claim action
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
    background: "#7c3aed",
    color: "#ffffff",
    cursor: "pointer"
};
