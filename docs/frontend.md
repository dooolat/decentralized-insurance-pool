# Frontend Notes

## Overview

The frontend is a React + Vite integration UI for the decentralized insurance
pool. It combines wallet status, dashboard reads, governance previews, and
protocol action forms in one screen.

## Current UI Sections

- wallet connection preview with visible wrong-network state handling
- dashboard read cards for collateral balance, governance voting power, and
  claimable policy summaries
- vault snapshot panel
- policy list preview
- risk type list preview
- action forms for deposit, buy policy, claim, AMM swap, and governance vote

## Error Handling

Readable frontend error mapping is prepared for common protocol and wallet
issues, including:

- user rejection
- wrong network / unsupported chain
- insufficient balance or allowance
- stale oracle state
- inactive risk type
- claim trigger not met

## Build Commands

```bash
cd frontend
npm install
npm run build
```

## Known Limitation

The UI is intentionally honest about its current integration state. Real live
transactions require deployed contract addresses, final ABI wiring, and verified
network configuration after Base Sepolia deployment.
