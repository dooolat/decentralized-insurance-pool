# Coverage

Command run locally on `develop`:

```bash
forge coverage
```

Result:

- Line coverage: `93.58% (758/810)`
- Statement coverage: `92.65% (781/843)`
- Branch coverage: `67.21% (82/122)`
- Function coverage: `88.44% (153/173)`

Status against target:

- `90%` line coverage target: **reached**
- Current measured line coverage is `93.58%`

High-coverage protocol areas after the Phase 5 testing + coverage boost pass:

- `contracts/oracle/ChainlinkOracleAdapter.sol`: `100.00%` lines
- `contracts/insurance/ClaimManager.sol`: `100.00%` lines
- `contracts/factory/InsuranceFactory.sol`: `100.00%` lines
- `contracts/upgrade/UpgradeableInsurancePoolV1.sol`: `100.00%` lines
- `contracts/upgrade/UpgradeableInsurancePoolV2.sol`: `100.00%` lines
- `script/Deploy.s.sol`: `100.00%` lines
- `script/VerifyDeployment.s.sol`: `100.00%` lines
- `script/UpgradeV2.s.sol`: `100.00%` lines
- `contracts/amm/InsuranceAMM.sol`: `94.20%` lines
- `contracts/insurance/InsurancePool.sol`: `94.79%` lines
- `contracts/vault/InsuranceVault.sol`: `88.24%` lines

Remaining weaker areas:

- `contracts/vault/InsuranceVault.sol`: `88.24%` lines, `86.67%` functions
- `test/helpers/ProtocolSystemFixture.sol`: `88.89%` lines, `72.73%` functions
- `test/helpers/BaseProtocolTest.sol`: `94.32%` lines, but only `43.48%` branch coverage
- `test/invariant/InsurancePoolInvariant.t.sol`: `66.67%` lines, `40.00%` functions
- production branch coverage is still lower than line coverage in:
  - `contracts/amm/InsuranceAMM.sol`: `55.56%` branches
  - `contracts/insurance/InsurancePool.sol`: `73.33%` branches

What was improved:

- added unit coverage for `ChainlinkOracleAdapter`, `InsurancePool`, `ClaimManager`, and `InsuranceAMM`
- expanded unit coverage for governance, factory, upgradeable pool, benchmark, vault, and deployment scripts
- added extra fuzz coverage for `InsurancePool`
- added fork test scaffolding for external protocol reads without faking local fork execution
- added direct script tests for deploy / verify / upgrade flows to cover script-based delivery requirements

Notes:

- `forge coverage` completed successfully; no fake coverage values are reported here
- local default `forge test` passes without an RPC URL because fork checks return early when `MAINNET_RPC_URL` is not configured
- `90%+` line coverage is now achieved, but branch and function coverage still lag behind line coverage in several helper/invariant paths
- fork tests are present in the suite, but this report does **not** claim live mainnet or sepolia fork validation because no RPC URL was configured locally
