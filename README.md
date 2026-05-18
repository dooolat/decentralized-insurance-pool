# Option E - Decentralized Insurance Pool

Course final project for Blockchain Technologies 2.

This repository contains a decentralized insurance pool prototype with
collateral underwriters, policy NFT issuance, Chainlink-triggered claims,
ERC-4626 vault accounting, a constant-product AMM, DAO governance, upgrade and
factory examples, frontend integration screens, subgraph indexing files, and
Base Sepolia deployment scripts.

## Team Ownership

- `Zhambyl`: smart contracts, integration, deployment scripts, final repo polish
- `Murat`: frontend integration and subgraph structure
- `Daulet`: tests, coverage, audit notes, gas report

## Core Modules

- `GovernanceToken`: `ERC20Votes` + `ERC20Permit` governance token
- `PolicyNFT`: ERC-721 policy receipt NFT
- `InsuranceVault`: ERC-4626 collateral vault with reserve-aware liquidity
- `RiskRegistry`: governance-managed risk catalog
- `ChainlinkOracleAdapter`: feed validation and staleness checks
- `InsurancePool`: policy purchase, accounting, policy lifecycle
- `ClaimManager`: oracle-triggered claim execution and payout flow
- `InsuranceAMM`: x*y=k AMM with fee and LP accounting
- `ProtocolGovernor` / `ProtocolTimelock`: governance execution path
- `UpgradeableInsurancePoolV1/V2`: UUPS upgrade example
- `InsuranceFactory`: CREATE / CREATE2 deployment helper
- `AssemblyBenchmark`: Solidity vs inline assembly benchmark helper

## Fresh Clone Setup

The Foundry dependencies in `lib/` are tracked as git submodules. After a fresh
clone, initialize them before running backend commands.

```bash
git clone https://github.com/dooolat/decentralized-insurance-pool.git
cd decentralized-insurance-pool
git checkout develop
git submodule update --init --recursive
forge build
forge test
forge coverage
```

Required submodules:

- `lib/openzeppelin-contracts`
- `lib/openzeppelin-contracts-upgradeable`
- `lib/forge-std`
- `lib/chainlink-brownie-contracts`

## Backend Commands

```bash
forge build
forge test
forge coverage
```

## Frontend Commands

```bash
cd frontend
npm install
npm run build
```

Use `npm run dev` for local UI preview when interactive testing is needed.

## Subgraph Status

The repository includes subgraph files under `subgraph/`:

- `subgraph/subgraph.yaml`
- `subgraph/schema.graphql`
- `subgraph/src/mappings.ts`
- `subgraph/queries.md`

The documented subgraph structure covers 8 entities with 6 query examples. The
subgraph manifest is updated with the recorded Base Sepolia deployment
addresses. A live hosted subgraph endpoint is not claimed unless it is deployed
separately.

## Deployment Status

Deployment scripts are included and parameterized:

- `script/Deploy.s.sol`
- `script/VerifyDeployment.s.sol`
- `script/UpgradeV2.s.sol`

Base Sepolia deployment addresses are recorded in
`deployments/base-sepolia.json`. The frontend contract configuration and
subgraph manifest are wired to those recorded addresses. This repository does
not add fake explorer verification links or claim a separate live subgraph
deployment.

## Testing Status

Latest validated `develop` results:

- `forge test`: `134 passed, 0 failed, 0 skipped`
- `forge coverage` line coverage: `93.60% (760/812)`
- frontend `npm run build`: passed
- fork tests are included in the suite, but live external fork execution still
  requires RPC URLs such as `MAINNET_RPC_URL` or `SEPOLIA_RPC_URL`

## Known Limitations

- the frontend contract configuration is updated with the recorded Base Sepolia deployment addresses, and the production build passes; full wallet-based live interaction should be verified with a funded testnet wallet before demonstration
- the subgraph manifest is updated with the recorded Base Sepolia deployment addresses; a live hosted subgraph endpoint is not claimed unless deployed separately
- Slither output should only be treated as final after `slither .` is actually rerun on the final branch
