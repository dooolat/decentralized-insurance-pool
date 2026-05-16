# Architecture Update (Day 4)

## Component Diagram

```mermaid
flowchart TB
    Frontend["React Frontend"] --> RPC["Base Sepolia RPC"]
    Frontend --> Graph["The Graph Subgraph"]

    subgraph Governance
        GovToken["GovernanceToken"]
        Governor["ProtocolGovernor"]
        Timelock["ProtocolTimelock"]
    end

    subgraph Insurance Core
        Vault["InsuranceVault"]
        Pool["InsurancePool"]
        ClaimManager["ClaimManager"]
        PolicyNFT["PolicyNFT"]
        Registry["RiskRegistry"]
        Oracle["ChainlinkOracleAdapter"]
    end

    subgraph DeFi Primitive
        AMM["InsuranceAMM"]
    end

    subgraph Upgrade and Deployment
        Factory["InsuranceFactory"]
        Proxy["ERC1967Proxy"]
        V1["UpgradeableInsurancePoolV1"]
        V2["UpgradeableInsurancePoolV2"]
        Bench["AssemblyBenchmark"]
    end

    GovToken --> Governor
    Governor --> Timelock
    Timelock --> Registry
    Timelock --> Vault
    Timelock --> Pool
    Pool --> PolicyNFT
    Pool --> Vault
    Pool --> Registry
    ClaimManager --> Oracle
    ClaimManager --> Pool
    ClaimManager --> Vault
    AMM --> GovToken
    Factory --> Pool
    Proxy --> V1
    Proxy -. upgraded to .-> V2
```

## Underwriter Deposit Sequence

```mermaid
sequenceDiagram
    participant U as Underwriter
    participant T as CollateralToken
    participant V as InsuranceVault

    U->>T: approve(vault, amount)
    U->>V: deposit(amount, receiver)
    V->>T: transferFrom(underwriter, vault, amount)
    V-->>U: mint ERC-4626 shares
```

## Policy Purchase Sequence

```mermaid
sequenceDiagram
    participant B as Buyer
    participant P as InsurancePool
    participant R as RiskRegistry
    participant V as InsuranceVault
    participant N as PolicyNFT

    B->>P: buyPolicy(riskTypeId, coverageAmount, duration)
    P->>R: getRiskType(riskTypeId)
    P->>P: calculatePremium()
    P->>V: verify free liquidity / reserve capacity
    P->>N: mint(policyId)
    P-->>B: emit PolicyCreated + PremiumPaid
```

## Oracle-Triggered Claim Payout Sequence

```mermaid
sequenceDiagram
    participant H as Policy Holder
    participant C as ClaimManager
    participant P as InsurancePool
    participant O as OracleAdapter
    participant F as Chainlink Feed
    participant V as InsuranceVault

    H->>C: executeClaim(policyId)
    C->>P: getPolicy(policyId)
    C->>O: getLatestPriceWithTimestamp(feed, stalenessLimit)
    O->>F: latestRoundData()
    O-->>C: validated price
    C->>P: markPolicyClaimed(policyId)
    C->>V: payClaim(recipient, payoutAmount)
```

## AMM Swap Sequence

```mermaid
sequenceDiagram
    participant Trader
    participant TokenIn
    participant AMM as InsuranceAMM
    participant TokenOut

    Trader->>TokenIn: approve(amm, amountIn)
    Trader->>AMM: swapExactInput(tokenIn, amountIn, minAmountOut, recipient)
    AMM->>AMM: compute x*y=k output with 0.3% fee
    AMM->>TokenOut: transfer(recipient, amountOut)
```

## Governance Parameter Update Sequence

```mermaid
sequenceDiagram
    participant Holder as Gov Holder
    participant Gov as ProtocolGovernor
    participant TL as ProtocolTimelock
    participant Registry as RiskRegistry

    Holder->>Gov: propose(calldata)
    Holder->>Gov: castVote()
    Gov->>TL: queue()
    TL-->>Gov: wait 2 days
    Gov->>TL: execute()
    TL->>Registry: updateRiskType(...)
```

## Proxy / UUPS Layout

- `UpgradeableInsurancePoolV1` defines the initial storage layout and `version() -> "v1"`.
- `UpgradeableInsurancePoolV2` appends new state such as `maxPolicyDuration` and returns `version() -> "v2"`.
- `ERC1967Proxy` holds state and delegates logic to the current implementation.
- Upgrade authorization is expected to sit behind `OwnableUpgradeable`, then later behind governance/timelock operations.

## Access-Control Roles

| Contract | Permission Model | Sensitive Actions |
| --- | --- | --- |
| `ProtocolGovernor` | token-weighted voting | propose, vote, queue, execute |
| `ProtocolTimelock` | proposer / executor / admin roles | delayed privileged calls |
| `RiskRegistry` | `AccessControl` | add, update, deactivate risk types |
| `InsuranceVault` | `Ownable` / governed owner | claim payouts, reserve-aware admin hooks |
| `InsurancePool` | `Ownable` / governed owner | claim manager wiring, pause hooks |
| `PolicyNFT` | `Ownable` + pool minter gate | set pool minter, base URI updates |
| `UpgradeableInsurancePoolV1/V2` | `OwnableUpgradeable` | UUPS upgrade authorization |
| `InsuranceFactory` | `Ownable` | CREATE / CREATE2 deployment paths |

## Trust Assumptions

- Chainlink feeds stay live, honest, and semantically correct for each risk type.
- Timelock ownership transfer is completed correctly after deployment.
- Underwriters understand that active coverage restricts free withdrawals.
- Governance token distribution is not so concentrated that DAO control becomes meaningless.
- The frontend and subgraph are convenience layers; protocol correctness still depends on the contracts.

## Design Decisions / ADRs

### ADR-01: Reserve-aware vault accounting

Vault withdrawals must respect active coverage so underwriters cannot drain the pool while protection is still sold.

### ADR-02: Separate claim manager

Claim validation is isolated from policy purchase logic to keep oracle checks and payout flow easier to audit.

### ADR-03: Risk registry instead of hardcoded risk params

Risk types change through governance rather than redeploying the whole pool for each new asset/feed combination.

### ADR-04: Timelock-governed admin path

Privileged parameter updates should move under `ProtocolTimelock` so governance actions have a visible delay.

### ADR-05: UUPS kept minimal

The upgrade demo intentionally adds only one new variable / function in V2 to make storage safety easier to reason about.
