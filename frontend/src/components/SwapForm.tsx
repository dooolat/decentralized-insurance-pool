import { useState } from "react";
import { contractPlaceholders } from "../lib/contracts";

type Props = {
    onStatus: (message: string) => void;
};

export function SwapForm({ onStatus }: Props) {
    const [amountIn, setAmountIn] = useState("250");
    const [minAmountOut, setMinAmountOut] = useState("1");

    return (
        <section style={panelStyle}>
            <h2 style={headingStyle}>Swap Through AMM</h2>
            <p style={copyStyle}>
                AMM contract: <code>{contractPlaceholders.insuranceAmm}</code>
            </p>
            <label style={labelStyle}>
                Amount in
                <input
                    style={inputStyle}
                    value={amountIn}
                    onChange={(event) => setAmountIn(event.target.value)}
                />
            </label>
            <label style={labelStyle}>
                Minimum amount out
                <input
                    style={inputStyle}
                    value={minAmountOut}
                    onChange={(event) => setMinAmountOut(event.target.value)}
                />
            </label>
            <button
                style={buttonStyle}
                type="button"
                onClick={() =>
                    onStatus(`Prepared AMM swap preview: amount in ${amountIn}, min out ${minAmountOut}.`)
                }
            >
                Prepare swap action
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
    background: "#b45309",
    color: "#ffffff",
    cursor: "pointer"
};
