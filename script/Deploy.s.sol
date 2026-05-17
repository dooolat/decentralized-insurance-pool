// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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

    struct CoreDeployment {
        GovernanceToken governanceToken;
        PolicyNFT policyNft;
        InsuranceVault insuranceVault;
        RiskRegistry riskRegistry;
        ChainlinkOracleAdapter oracleAdapter;
        InsurancePool insurancePool;
        ClaimManager claimManager;
        InsuranceAMM insuranceAmm;
    }

    struct GovernanceDeployment {
        ProtocolTimelock timelock;
        ProtocolGovernor governor;
        InsuranceFactory factory;
    }

    struct UpgradeDeployment {
        UpgradeableInsurancePoolV1 implementation;
        ERC1967Proxy proxy;
        AssemblyBenchmark benchmark;
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

        CoreDeployment memory core = _deployCore(config);
        GovernanceDeployment memory governance = _deployGovernance(config, core.governanceToken);
        UpgradeDeployment memory upgrade = _deployUpgradeAndBenchmark(config);

        vm.stopBroadcast();

        result = DeploymentResult({
            governanceToken: address(core.governanceToken),
            policyNft: address(core.policyNft),
            insuranceVault: address(core.insuranceVault),
            riskRegistry: address(core.riskRegistry),
            oracleAdapter: address(core.oracleAdapter),
            insurancePool: address(core.insurancePool),
            claimManager: address(core.claimManager),
            insuranceAmm: address(core.insuranceAmm),
            timelock: address(governance.timelock),
            governor: address(governance.governor),
            factory: address(governance.factory),
            upgradeableImplementation: address(upgrade.implementation),
            upgradeableProxy: address(upgrade.proxy),
            benchmark: address(upgrade.benchmark)
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

    function _deployCore(
        DeploymentConfig memory config
    ) internal returns (CoreDeployment memory core) {
        core.governanceToken =
            new GovernanceToken(config.initialOwner, config.initialGovernanceSupply);
        core.policyNft = new PolicyNFT(config.initialOwner, config.policyBaseUri);
        core.riskRegistry = new RiskRegistry(config.initialOwner);
        core.oracleAdapter = new ChainlinkOracleAdapter();
        core.insuranceVault = new InsuranceVault(
            IERC20(config.collateralAsset),
            config.initialOwner,
            "Insurance Vault Share",
            "IVS"
        );

        // Current develop still contains placeholder versions of these modules.
        // The AMM constructor remains placeholder until the dedicated AMM PR is
        // merged, but the insurance flow modules already have their real
        // constructors on this branch and should be deployed accordingly.
        core.insurancePool = new InsurancePool(
            IERC20(config.collateralAsset),
            core.insuranceVault,
            core.policyNft,
            core.riskRegistry,
            config.initialOwner
        );
        core.claimManager = new ClaimManager(
            core.insurancePool,
            core.riskRegistry,
            core.insuranceVault,
            core.policyNft,
            core.oracleAdapter,
            config.initialOwner
        );
        core.insuranceAmm =
            new InsuranceAMM(config.collateralAsset, address(core.governanceToken));
    }

    function _deployGovernance(
        DeploymentConfig memory config,
        GovernanceToken governanceToken
    ) internal returns (GovernanceDeployment memory governance) {
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](1);
        executors[0] = address(0);

        governance.timelock = new ProtocolTimelock(proposers, executors, config.initialOwner);
        governance.governor = new ProtocolGovernor(
            governanceToken,
            governance.timelock,
            config.initialGovernanceSupply
        );
        governance.factory = new InsuranceFactory(config.initialOwner);
    }

    function _deployUpgradeAndBenchmark(
        DeploymentConfig memory config
    ) internal returns (UpgradeDeployment memory upgrade) {
        upgrade.implementation = new UpgradeableInsurancePoolV1();
        upgrade.proxy = new ERC1967Proxy(
            address(upgrade.implementation),
            abi.encodeCall(
                UpgradeableInsurancePoolV1.initialize,
                (config.initialOwner, config.collateralAsset)
            )
        );
        upgrade.benchmark = new AssemblyBenchmark();
    }
}
