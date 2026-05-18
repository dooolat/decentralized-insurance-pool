import { formatUnits, parseUnits } from "viem";

export function formatToken(value?: bigint, decimals = 18, precision = 4): string {
  if (value === undefined) return "-";
  const normalized = Number(formatUnits(value, decimals));
  return normalized.toLocaleString(undefined, {
    maximumFractionDigits: precision,
  });
}

export function parseTokenInput(value: string, decimals = 18): bigint {
  return parseUnits(value || "0", decimals);
}

