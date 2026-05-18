import { useState } from "react";
import { contractPlaceholders, proposalPreview } from "../lib/contracts";

type Props = {
    onStatus: (message: string) => void;
};

export function VotePanel({ onStatus }: Props) {
    const [proposalId, setProposalId] = useState(proposalPreview[0]?.id ?? "");
    const [support, setSupport] = useState("1");

    return (
        <section style={panelStyle}>
            <h2 style={headingStyle}>Vote On Proposal</h2>
            <p style={copyStyle}>
                Governor contract: <code>{contractPlaceholders.protocolGovernor}</code>
            </p>
            <label style={labelStyle}>
                Proposal ID
                <input
                    style={inputStyle}
                    value={proposalId}
                    onChange={(event) => setProposalId(event.target.value)}
                />
            </label>
            <label style={labelStyle}>
                Support
                <select
                    style={inputStyle}
                    value={support}
                    onChange={(event) => setSupport(event.target.value)}
                >
                    <option value="0">Against</option>
                    <option value="1">For</option>
                    <option value="2">Abstain</option>
                </select>
            </label>
            <button
                style={buttonStyle}
                type="button"
                onClick={() =>
                    onStatus(`Prepared governance vote for proposal ${proposalId} with support ${support}.`)
                }
            >
                Prepare vote action
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
    background: "#334155",
    color: "#ffffff",
    cursor: "pointer"
};
