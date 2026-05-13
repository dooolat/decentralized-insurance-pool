# Security Audit

## Scope

This Day 2 report covers the first protocol-core contracts added after the bootstrap repository:

- `GovernanceToken`
- `PolicyNFT`
- `InsuranceVault`
- `RiskRegistry`

The full insurance flow, AMM, governance execution, deployment scripts, and upgrade path are out
of scope for this initial draft and will be added in later iterations.

## Methodology

The early review process for these modules focuses on:

- manual inspection of ownership and privileged actions
- review of minting and delegation assumptions
- review of vault withdrawal constraints versus reserved liquidity
- review of risk parameter validation and update paths
- preparation for static analysis and tests once the dependency setup is finalized

## Initial Focus Areas

- access control on minters and admins
- governance token delegation and vote accounting assumptions
- undercollateralization risk in the underwriting vault
- invalid oracle or premium parameters in the risk registry

## Pending Sections

- findings table
- reentrancy case study
- access-control case study
- governance attack analysis
- oracle risk appendix
