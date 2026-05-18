# Coverage

Command run locally on `develop`:

```bash
forge coverage
```

Latest measured result:

- `forge test`: `134 passed, 0 failed, 0 skipped`
- Line coverage: `93.60% (760/812)`
- Statement coverage: `92.67% (784/846)`
- Branch coverage: `66.94% (83/124)`
- Function coverage: `88.44% (153/173)`

Status against target:

- `90%` line coverage target: **reached**
- Current measured line coverage is `93.60%`

Notes:

- `forge coverage` completed successfully; no fake coverage values are reported here
- local default `forge test` passes without an RPC URL because fork checks return early when `MAINNET_RPC_URL` is not configured
- fork tests are present in the suite, but this report does **not** claim live mainnet or sepolia fork validation because no RPC URL was configured locally
- branch and function coverage still trail line coverage in several helper and invariant paths even though the overall line target is exceeded
