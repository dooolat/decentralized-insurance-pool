# Subgraph Notes

## Overview

The repository includes a Graph subgraph structure for indexing protocol
activity after deployment. The current files document the schema, manifest,
example queries, and AssemblyScript mappings.

## Indexed Scope

- entities in `schema.graphql`: `8`
- documented GraphQL queries in `queries.md`: `6`

Main indexed records include:

- `Policy`
- `Claim`
- `RiskType`
- `VaultDeposit`
- `Swap`
- `LiquidityPosition`
- `GovernanceProposal`
- `Vote`

## Required Files

- `subgraph/subgraph.yaml`
- `subgraph/schema.graphql`
- `subgraph/src/mappings.ts`
- `subgraph/queries.md`

## Deployment Status

Manifest addresses are placeholders and must be replaced after a real Base
Sepolia deployment. This repository does not claim a live hosted service or a
deployed production subgraph endpoint.
