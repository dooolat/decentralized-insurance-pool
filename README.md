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

The documented subgraph structure covers 8 entities with 6 query examples.
Manifest addresses remain placeholders until a real deployment is completed, so
this repository does not claim a live deployed subgraph endpoint.

## Deployment Status

Deployment scripts are included and parameterized:

- `script/Deploy.s.sol`
- `script/VerifyDeployment.s.sol`
- `script/UpgradeV2.s.sol`

`deployments/base-sepolia.json` is a template file unless a real deployment and
verification pass has been completed. This repository does not claim live
deployed or verified addresses by default.

## Testing Status

Latest validated `develop` results:

- `forge test`: `134 passed, 0 failed, 0 skipped`
- `forge coverage` line coverage: `93.58% (758/810)`
- fork tests are included in the suite, but live external fork execution still
  requires RPC URLs such as `MAINNET_RPC_URL` or `SEPOLIA_RPC_URL`

## Known Limitations

- frontend contract addresses remain placeholders until a real L2 deployment is completed
- subgraph manifest addresses remain placeholders until a real L2 deployment is completed
- deployment verification status depends on a real network broadcast and verification pass
- Slither output should only be treated as final after `slither .` is actually rerun on the final branch
