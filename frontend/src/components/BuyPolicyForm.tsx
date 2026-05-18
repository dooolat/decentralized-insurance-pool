import { useMemo, useState } from "react";
import { contractPlaceholders, riskTypeOptions } from "../lib/contracts";

type Props = {
    onStatus: (message: string) => void;
};

export function BuyPolicyForm({ onStatus }: Props) {
    const [riskTypeId, setRiskTypeId] = useState(String(riskTypeOptions[0].id));
    const [coverageAmount, setCoverageAmount] = useState("1000");
    const [durationDays, setDurationDays] = useState("30");

    const selectedRisk = useMemo(
        () => riskTypeOptions.find((risk) => String(risk.id) === riskTypeId),
        [riskTypeId]
    );

    return (
        <section style={panelStyle}>
            <h2 style={headingStyle}>Buy Policy</h2>
            <p style={copyStyle}>
                Policy writes will target <code>{contractPlaceholders.insurancePool}</code>.
            </p>
            <label style={labelStyle}>
                Risk type
                <select
                    style={inputStyle}
                    value={riskTypeId}
                    onChange={(event) => setRiskTypeId(event.target.value)}
                >
                    {riskTypeOptions.map((risk) => (
                        <option key={risk.id} value={risk.id}>
                            {risk.name}
                        </option>
                    ))}
                </select>
            </label>
            <label style={labelStyle}>
                Coverage amount
                <input
                    style={inputStyle}
                    value={coverageAmount}
                    onChange={(event) => setCoverageAmount(event.target.value)}
                />
            </label>
            <label style={labelStyle}>
                Duration (days)
                <input
                    style={inputStyle}
                    value={durationDays}
                    onChange={(event) => setDurationDays(event.target.value)}
                />
            </label>
            <p style={noteStyle}>
                Preview premium rate: {selectedRisk?.premiumRateBps ?? 0} bps
            </p>
            <button
                style={buttonStyle}
                type="button"
                onClick={() =>
                    onStatus(
                        `Prepared policy purchase for risk ${riskTypeId}, coverage ${coverageAmount}, duration ${durationDays} days.`
                    )
                }
            >
                Prepare policy purchase
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

const noteStyle = {
    color: "#475569",
    marginTop: 0,
    marginBottom: "0.9rem"
};

const buttonStyle = {
    border: "none",
    borderRadius: "999px",
    padding: "0.75rem 1rem",
    background: "#1d4ed8",
    color: "#ffffff",
    cursor: "pointer"
};
