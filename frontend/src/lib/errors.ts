export function toReadableError(error: unknown): string {
  const message = error instanceof Error ? error.message : String(error);

  if (message.includes("User rejected") || message.includes("rejected")) {
    return "Transaction rejected in wallet.";
  }
  if (message.includes("wrong network") || message.includes("chain")) {
    return "Wrong network. Please switch to Base Sepolia.";
  }
  if (message.includes("insufficient")) {
    return "Insufficient balance or allowance for this action.";
  }
  if (message.includes("InactiveRiskType")) {
    return "That risk type is inactive.";
  }
  if (message.includes("StaleOraclePrice")) {
    return "Oracle data is stale. Try again after the feed updates.";
  }
  if (message.includes("ClaimConditionNotMet") || message.includes("ClaimRejected")) {
    return "Claim condition not met for that policy.";
  }
  if (message.includes("CoverageExceeds")) {
    return "Requested coverage exceeds the pool or risk capacity.";
  }

  return "Transaction failed. Check wallet confirmation and contract configuration.";
}

