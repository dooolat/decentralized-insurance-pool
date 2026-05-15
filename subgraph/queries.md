# Day 4 Subgraph Query Examples

These queries are examples only. Replace manifest placeholder addresses and deploy the subgraph before wiring the frontend to a live endpoint.

## 1. Active policies

```graphql
query ActivePolicies {
  policies(first: 10, where: { status: "ACTIVE" }, orderBy: startTime, orderDirection: desc) {
    id
    buyer
    riskTypeId
    premium
    coverageAmount
    startTime
    endTime
  }
}
```

## 2. Claim payout history

```graphql
query ClaimHistory {
  claims(first: 20, orderBy: createdAt, orderDirection: desc) {
    id
    payoutAmount
    recipient
    txHash
    policy {
      id
      status
    }
  }
}
```

## 3. Risk type catalog

```graphql
query RiskCatalog {
  riskTypes(first: 20, orderBy: updatedAt, orderDirection: desc) {
    id
    name
    premiumRateBps
    maxCoverage
    triggerThreshold
    stalenessLimit
    active
  }
}
```

## 4. Vault deposits

```graphql
query VaultDeposits {
  vaultDeposits(first: 20, orderBy: createdAt, orderDirection: desc) {
    id
    caller
    owner
    assets
    shares
    txHash
  }
}
```

## 5. Swap activity

```graphql
query SwapActivity {
  swaps(first: 20, orderBy: createdAt, orderDirection: desc) {
    id
    sender
    tokenIn
    amountIn
    amountOut
    recipient
  }
}
```

## 6. Governance proposals and votes

```graphql
query GovernanceState {
  governanceProposals(first: 10, orderBy: updatedAt, orderDirection: desc) {
    proposalId
    description
    state
    forVotes
    againstVotes
    abstainVotes
  }
  votes(first: 20, orderBy: createdAt, orderDirection: desc) {
    id
    voter
    support
    weight
    proposal {
      proposalId
    }
  }
}
```
