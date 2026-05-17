# Decentralized Insurance Pool

Option E final project for Blockchain Technologies 2.

This repository contains the smart contracts, Foundry tests, frontend scaffold,
deployment scripts, and subgraph files for a decentralized insurance pool
prototype.

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
```

Required submodules:

- `lib/openzeppelin-contracts`
- `lib/openzeppelin-contracts-upgradeable`
- `lib/forge-std`
- `lib/chainlink-brownie-contracts`

## Frontend

```bash
cd frontend
npm install
npm run build
```

## Deployment Status

Deployment scripts are included, but real L2 addresses should only be added
after successful deployment and verification.
