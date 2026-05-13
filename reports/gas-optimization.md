# Gas Optimization

## Day 2 Baseline

This report starts the gas tracking structure for the protocol. No benchmark numbers are claimed
yet, because the protocol is still being implemented in separate feature branches.

## Planned Measurement Targets

- governance token transfer and delegation
- policy NFT minting
- vault deposit and withdrawal
- risk registry add and update operations

## Initial Tracking Table

| Operation | Contract | Current Gas | Notes |
| --- | --- | --- | --- |
| delegate | GovernanceToken | TODO | measure after tests are added |
| mint policy NFT | PolicyNFT | TODO | depends on later pool integration |
| deposit | InsuranceVault | TODO | measure once Foundry setup is ready |
| add risk type | RiskRegistry | TODO | measure with realistic inputs |

## Follow-up Work

- compare baseline and optimized paths
- add L1 vs L2 framing
- connect future assembly benchmark results
