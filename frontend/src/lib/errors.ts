const KNOWN_ERROR_MESSAGES = [
    "Transaction rejected in wallet.",
    "Wrong network. Please switch to Base Sepolia.",
    "Insufficient balance or allowance for this action.",
    "Oracle data is stale. Try again after the feed updates.",
    "That risk type is inactive.",
    "Claim condition not met for that policy."
] as const;

export function toReadableError(error: unknown): string {
    const message = error instanceof Error ? error.message : String(error);
    const lowered = message.toLowerCase();

    if (lowered.includes("user rejected") || lowered.includes("rejected")) {
        return KNOWN_ERROR_MESSAGES[0];
    }
    if (lowered.includes("wrong network") || lowered.includes("chain")) {
        return KNOWN_ERROR_MESSAGES[1];
    }
    if (lowered.includes("insufficient")) {
        return KNOWN_ERROR_MESSAGES[2];
    }
    if (message.includes("StaleOraclePrice")) {
        return KNOWN_ERROR_MESSAGES[3];
    }
    if (message.includes("InactiveRiskType")) {
        return KNOWN_ERROR_MESSAGES[4];
    }
    if (message.includes("ClaimConditionNotMet") || message.includes("ClaimRejected")) {
        return KNOWN_ERROR_MESSAGES[5];
    }

    return "Transaction failed. Check wallet confirmation, network, and contract configuration.";
}

export function knownFrontendErrors(): readonly string[] {
    return KNOWN_ERROR_MESSAGES;
}
