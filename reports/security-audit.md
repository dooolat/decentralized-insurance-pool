# Security Audit Update (Day 4)

## Scope Status

This document is still an in-progress audit companion for the course project. It focuses on the protocol design and the currently implemented contract set. Final findings should only be written after the last integration and test pass.

## Centralization Analysis

- Governance exists, but practical decentralization depends on token distribution after deployment.
- Timelock ownership is the intended control boundary for vault, pool, registry, NFT admin hooks, and upgrade authorization.
- Any temporary deployer privileges remaining after deployment should be treated as a release blocker.

## Access Control Analysis

- `RiskRegistry` should restrict risk parameter changes through `AccessControl` and timelock-managed roles.
- `PolicyNFT` must keep minting exclusive to the insurance pool or another explicitly approved minter.
- `InsuranceVault` and upgradeable modules should avoid unrestricted admin writes that could bypass liquidity or upgrade assumptions.
- Factory deployment helpers should stay owner-gated or timelock-gated to avoid arbitrary module deployment spam.

## Reentrancy Discussion

Key surfaces:
- vault withdrawals
- claim payouts
- AMM swaps / liquidity removal
- policy purchase flows that transfer funds and update accounting

Expected mitigation pattern:
- checks-effects-interactions ordering
- explicit reentrancy guards where re-entry could combine token callbacks with mutable accounting

## Oracle Stale Price Analysis

- Risk definitions include `stalenessLimit`, so the oracle adapter should revert when feed timestamps are too old.
- A stale-price rejection is preferable to paying out or denying claims using obviously expired data.
- Frontend error handling should surface stale-price conditions clearly to users instead of raw RPC errors.

## Price Manipulation / Feed Depeg Analysis

- Chainlink reduces single-source manipulation risk, but each feed still needs semantic review.
- Governance must ensure the chosen feed actually represents the insured event and not a loosely related proxy.
- Feed depeg scenarios are part of the protocol’s domain model and should be reflected in threshold design, not ignored as out-of-scope.

## Double-Claim Risk

- Once a policy is claimed, state must move irreversibly away from `Active`.
- `ClaimManager` should verify policy ownership / approval and mark policy state before payout completion.
- Invariant testing should keep a dedicated assertion that no policy can produce more than one successful payout.

## Vault Undercollateralization Risk

- Active coverage creates a reserve burden on the vault.
- Withdraw / redeem logic should block exits that would make guaranteed coverage larger than free liquidity.
- Claim payout hooks and reserve release must stay synchronized with policy lifecycle events.

## Governance Attack Analysis

### Flash-loan governance attack

- `ERC20Votes` checkpoints help, but governance safety still depends on whether the token becomes borrowable elsewhere.
- If a lending market emerges, governance assumptions should be revisited.

### Whale attack

- A concentrated supply can dominate both proposal creation and voting outcomes.
- This is mostly a distribution and treasury-policy issue, but it should be documented explicitly.

### Proposal spam

- A non-trivial proposal threshold helps, but UI filtering and proposer accountability still matter.
- Draft governance docs should specify why `1%` was chosen and what trade-off it makes.

### Timelock bypass

- Final deployment verification must check that no backdoor owner/admin remains outside the timelock path.
- Any helper role granted directly to a deployer wallet after setup should be considered a critical issue until removed.

## Day 4 Follow-Up Checklist

- confirm claim payout ordering after the final insurance-flow merge
- review AMM slippage and reserve update logic with fuzz/invariant coverage
- review UUPS upgrade authorization and storage extension assumptions
- append Slither output summary only after the actual run used for the team branch
