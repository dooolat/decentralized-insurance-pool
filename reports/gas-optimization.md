# Gas Optimization Update (Day 4)

## Measurement Status

This Day 4 document is a template and optimization notebook. It does not claim fresh benchmark numbers for the team repository unless the corresponding command is rerun on the exact branch under review.

Primary command to use later:

```bash
forge test --gas-report
```

Optional command for broader measurement:

```bash
forge snapshot
```

## Initial Benchmark Table

| Operation | Contract / Function | Measurement Status | Notes |
| --- | --- | --- | --- |
| Deposit to vault | `InsuranceVault.deposit` | To be measured after final integration | ERC-4626 entry path |
| Withdraw from vault | `InsuranceVault.withdraw` | To be measured after final integration | includes reserve checks |
| Buy policy | `InsurancePool.buyPolicy` | To be measured after final integration | premium transfer + PolicyNFT mint |
| Execute claim | `ClaimManager.executeClaim` | To be measured after final integration | oracle validation + payout |
| AMM swap | `InsuranceAMM.swapExactInput` | To be measured after final integration | constant product with fee |
| Governance vote | `ProtocolGovernor.castVote` | To be measured after final integration | voting checkpoint flow |

## Solidity vs Yul Benchmark

The benchmark module should compare one pure Solidity implementation against one inline Yul implementation of the same logic.

Suggested benchmark focus:
- array sum
- min / max scan
- hash helper

Template:

| Function Pair | Solidity Result | Yul Result | Delta | Status |
| --- | --- | --- | --- | --- |
| `sumSolidity` vs `sumAssembly` | To be measured | To be measured | To be measured | Pending benchmark run |

## L1 vs L2 Gas Comparison Template

This section should remain a template until real measurements are rerun on the final branch and paired with explicit gas-price assumptions.

| Operation | Median Gas | Example L1 Cost | Example L2 Cost | Notes |
| --- | --- | --- | --- | --- |
| Deposit to vault | To be measured | To be derived | To be derived | ERC-4626 flow |
| Withdraw from vault | To be measured | To be derived | To be derived | reserve-aware exit |
| Buy policy | To be measured | To be derived | To be derived | policy + premium flow |
| Execute claim | To be measured | To be derived | To be derived | oracle-triggered payout |
| AMM swap | To be measured | To be derived | To be derived | x*y=k swap |
| Governance vote | To be measured | To be derived | To be derived | token checkpoint vote |

## Optimization Themes To Track

- immutable addresses where upgradeability is not required
- minimizing redundant storage reads in premium and payout paths
- keeping AMM reserve updates centralized
- avoiding temporary premium custody when routing into the vault
- appending storage in upgradeable V2 rather than mutating V1 slot order
- keeping inline assembly limited to isolated benchmark or helper hotspots

## Follow-Up After Final Integration

- rerun `forge test --gas-report`
- record per-operation medians
- append benchmark deltas for Solidity vs Yul helper
- note any gas regressions introduced by governance, claim, or upgrade flows
