export function toReadableError(error: unknown): string {
  const message = error instanceof Error ? error.message : String(error);
  const normalizedMessage = message.trim();

  if (normalizedMessage.includes("User rejected") || normalizedMessage.includes("rejected")) {
    return "Transaction rejected in wallet.";
  }
  if (normalizedMessage.includes("wrong network") || normalizedMessage.includes("chain")) {
    return "Wrong network. Please switch to Base Sepolia.";
  }
  if (normalizedMessage.includes("insufficient")) {
    return "Insufficient balance or allowance for this action.";
  }
  if (normalizedMessage.includes("InactiveRiskType")) {
    return "That risk type is inactive.";
  }
  if (normalizedMessage.includes("StaleOraclePrice")) {
    return "Oracle data is stale. Try again after the feed updates.";
  }
  if (
    normalizedMessage.includes("ClaimConditionNotMet")
    || normalizedMessage.includes("ClaimRejected")
  ) {
    return "Claim condition not met for that policy.";
  }
  if (normalizedMessage.includes("CoverageExceeds")) {
    return "Requested coverage exceeds the pool or risk capacity.";
  }
  if (normalizedMessage.includes("InvalidDuration")) {
    return "Policy duration is outside the allowed range.";
  }
  if (normalizedMessage.includes("InvalidAmount")) {
    return "Amount must be greater than zero and satisfy the contract limits.";
  }
  if (normalizedMessage.includes("SlippageExceeded")) {
    return "Swap output is below your minimum governance out value.";
  }
  if (normalizedMessage && normalizedMessage !== "[object Object]") {
    return `Transaction failed: ${normalizedMessage}`;
  }

  return "Transaction failed. Check wallet confirmation and contract configuration.";
}

