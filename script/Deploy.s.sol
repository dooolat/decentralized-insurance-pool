// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { GovernanceToken } from "../contracts/token/GovernanceToken.sol";
import { PolicyNFT } from "../contracts/nft/PolicyNFT.sol";
import { InsuranceVault } from "../contracts/vault/InsuranceVault.sol";
import { RiskRegistry } from "../contracts/insurance/RiskRegistry.sol";
import { ChainlinkOracleAdapter } from "../contracts/oracle/ChainlinkOracleAdapter.sol";
import { InsurancePool } from "../contracts/insurance/InsurancePool.sol";
import { ClaimManager } from "../contracts/insurance/ClaimManager.sol";
import { InsuranceAMM } from "../contracts/amm/InsuranceAMM.sol";
import { ProtocolGovernor } from "../contracts/governance/ProtocolGovernor.sol";
import { ProtocolTimelock } from "../contracts/governance/ProtocolTimelock.sol";
import { InsuranceFactory } from "../contracts/factory/InsuranceFactory.sol";
import { UpgradeableInsurancePoolV1 } from "../contracts/upgrade/UpgradeableInsurancePoolV1.sol";
import { AssemblyBenchmark } from "../contracts/benchmark/AssemblyBenchmark.sol";

contract Deploy is Script {
    struct DeploymentConfig {
        uint256 deployerPrivateKey;
        address initialOwner;
        address collateralAsset;
        uint256 initialGovernanceSupply;
        string policyBaseUri;
    }

    struct DeploymentResult {
        address governanceToken;
        address policyNft;
        address insuranceVault;
        address riskRegistry;
        address oracleAdapter;
        address insurancePool;
        address claimManager;
        address insuranceAmm;
        address timelock;
        address governor;
        address factory;
        address upgradeableImplementation;
        address upgradeableProxy;
        address benchmark;
    }

    function run() external returns (DeploymentResult memory result) {
        DeploymentConfig memory config = _loadConfig();

        vm.startBroadcast(config.deployerPrivateKey);

        GovernanceToken governanceToken =
            new GovernanceToken(config.initialOwner, config.initialGovernanceSupply);
        PolicyNFT policyNft = new PolicyNFT(config.initialOwner, config.policyBaseUri);
        RiskRegistry riskRegistry = new RiskRegistry(config.initialOwner);
        ChainlinkOracleAdapter oracleAdapter = new ChainlinkOracleAdapter();

        // The remaining constructor arguments are intentionally parameterized.
        // Fill them from real deployment inputs once collateral asset and supporting
        // contracts are finalized in the integration branch.
        InsuranceVault vault =
            new InsuranceVault(config.collateralAsset, config.initialOwner, "Insurance Vault Share", "IVS");
        InsurancePool pool =
            new InsurancePool(config.collateralAsset, address(vault), address(policyNft), address(riskRegistry), config.initialOwner);
        ClaimManager claimManager =
            new ClaimManager(address(pool), address(riskRegistry), address(vault), address(policyNft), address(oracleAdapter), config.initialOwner);
        InsuranceAMM amm = new InsuranceAMM(config.collateralAsset, address(governanceToken));

        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](1);
        executors[0] = address(0);
        ProtocolTimelock timelock = new ProtocolTimelock(proposers, executors, config.initialOwner);
        ProtocolGovernor governor =
            new ProtocolGovernor(governanceToken, timelock, config.initialGovernanceSupply);
        InsuranceFactory factory = new InsuranceFactory(config.initialOwner);

        UpgradeableInsurancePoolV1 implementation = new UpgradeableInsurancePoolV1();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(
                UpgradeableInsurancePoolV1.initialize,
                (config.initialOwner, config.collateralAsset)
            )
        );

        AssemblyBenchmark benchmark = new AssemblyBenchmark();

        vm.stopBroadcast();

        result = DeploymentResult({
            governanceToken: address(governanceToken),
            policyNft: address(policyNft),
            insuranceVault: address(vault),
            riskRegistry: address(riskRegistry),
            oracleAdapter: address(oracleAdapter),
            insurancePool: address(pool),
            claimManager: address(claimManager),
            insuranceAmm: address(amm),
            timelock: address(timelock),
            governor: address(governor),
            factory: address(factory),
            upgradeableImplementation: address(implementation),
            upgradeableProxy: address(proxy),
            benchmark: address(benchmark)
        });

        // Intentionally no fake address persistence. Real deployments can write
        // verified addresses into deployments/base-sepolia.json after broadcast.
    }

    function _loadConfig() internal view returns (DeploymentConfig memory config) {
        config.deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        config.initialOwner = vm.envAddress("INITIAL_OWNER");
        config.collateralAsset = vm.envAddress("COLLATERAL_ASSET");
        config.initialGovernanceSupply = vm.envUint("INITIAL_GOV_SUPPLY");
        config.policyBaseUri = vm.envString("POLICY_BASE_URI");
    }
}
