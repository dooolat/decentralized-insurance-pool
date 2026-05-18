// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { GovernanceToken } from "../../contracts/token/GovernanceToken.sol";
import { PolicyNFT } from "../../contracts/nft/PolicyNFT.sol";
import { InsuranceVault } from "../../contracts/vault/InsuranceVault.sol";
import { RiskRegistry } from "../../contracts/insurance/RiskRegistry.sol";
import { InsurancePool } from "../../contracts/insurance/InsurancePool.sol";
import { ClaimManager } from "../../contracts/insurance/ClaimManager.sol";
import { ChainlinkOracleAdapter } from "../../contracts/oracle/ChainlinkOracleAdapter.sol";
import { InsuranceAMM } from "../../contracts/amm/InsuranceAMM.sol";
import { ProtocolGovernor } from "../../contracts/governance/ProtocolGovernor.sol";
import { ProtocolTimelock } from "../../contracts/governance/ProtocolTimelock.sol";
import { InsuranceFactory } from "../../contracts/factory/InsuranceFactory.sol";
import { UpgradeableInsurancePoolV1 } from "../../contracts/upgrade/UpgradeableInsurancePoolV1.sol";
import { UpgradeableInsurancePoolV2 } from "../../contracts/upgrade/UpgradeableInsurancePoolV2.sol";
import { AssemblyBenchmark } from "../../contracts/benchmark/AssemblyBenchmark.sol";
import { FixtureCollateralToken } from "../helpers/ProtocolSystemFixture.sol";
import { Deploy } from "../../script/Deploy.s.sol";
import { VerifyDeployment } from "../../script/VerifyDeployment.s.sol";
import { UpgradeV2 } from "../../script/UpgradeV2.s.sol";

contract MockClockToken {
    function clock() external pure returns (uint48) {
        return 1;
    }
}

contract MockGovernorLike {
    address public token;
    uint256 private _initialSupply;

    constructor(address token_, uint256 initialSupply_) {
        token = token_;
        _initialSupply = initialSupply_;
    }

    function votingDelay() external pure returns (uint256) {
        return 1 days;
    }

    function votingPeriod() external pure returns (uint256) {
        return 1 weeks;
    }

    function proposalThreshold() external view returns (uint256) {
        return _initialSupply / 100;
    }

    function quorum(uint256) external view returns (uint256) {
        return (_initialSupply * 4) / 100;
    }
}

contract MockTimelockLike {
    uint256 public constant MIN_DELAY = 2 days;
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    mapping(bytes32 role => mapping(address account => bool hasRole_)) private _roles;

    function getMinDelay() external pure returns (uint256) {
        return MIN_DELAY;
    }

    function grantRole(bytes32 role, address account) external {
        _roles[role][account] = true;
    }

    function hasRole(bytes32 role, address account) external view returns (bool) {
        return _roles[role][account];
    }
}

contract MockOwnableLike {
    address private _owner;

    constructor(address owner_) {
        _owner = owner_;
    }

    function owner() external view returns (address) {
        return _owner;
    }
}

contract MockRiskRegistryAccess {
    bytes32 public constant RISK_MANAGER_ROLE = keccak256("RISK_MANAGER_ROLE");

    mapping(bytes32 role => mapping(address account => bool hasRole_)) private _roles;

    function grantRole(bytes32 role, address account) external {
        _roles[role][account] = true;
    }

    function hasRole(bytes32 role, address account) external view returns (bool) {
        return _roles[role][account];
    }
}

contract DeploymentScriptsTest is Test {
    uint256 private constant DEPLOYER_PRIVATE_KEY = 0xA11CE;
    uint256 private constant INITIAL_GOV_SUPPLY = 1_000_000 ether;

    function testDeployScriptCreatesExpectedProtocolModules() public {
        address initialOwner = makeAddr("deploy-script-owner");
        FixtureCollateralToken collateralToken = new FixtureCollateralToken();

        _setDeployEnv(initialOwner, address(collateralToken));

        Deploy.DeploymentResult memory result = new Deploy().run();

        assertEq(GovernanceToken(result.governanceToken).owner(), initialOwner);
        assertEq(PolicyNFT(result.policyNft).owner(), initialOwner);
        assertEq(InsuranceVault(result.insuranceVault).owner(), initialOwner);
        assertEq(RiskRegistry(result.riskRegistry).hasRole(0x00, initialOwner), true);
        assertEq(InsurancePool(result.insurancePool).owner(), initialOwner);
        assertEq(ClaimManager(result.claimManager).owner(), initialOwner);
        assertEq(InsuranceFactory(result.factory).owner(), initialOwner);
        assertEq(InsuranceVault(result.insuranceVault).asset(), address(collateralToken));
        assertEq(InsurancePool(result.insurancePool).vault(), result.insuranceVault);
        assertEq(InsurancePool(result.insurancePool).policyNFT(), result.policyNft);
        assertEq(InsurancePool(result.insurancePool).riskRegistry(), result.riskRegistry);
        assertEq(address(ClaimManager(result.claimManager).insurancePool()), result.insurancePool);
        assertEq(address(ClaimManager(result.claimManager).insuranceVault()), result.insuranceVault);
        assertEq(address(ClaimManager(result.claimManager).policyNft()), result.policyNft);
        assertEq(address(ClaimManager(result.claimManager).riskRegistry()), result.riskRegistry);
        assertEq(address(ClaimManager(result.claimManager).oracleAdapter()), result.oracleAdapter);
        assertEq(address(InsuranceAMM(result.insuranceAmm).token0()), address(collateralToken));
        assertEq(address(InsuranceAMM(result.insuranceAmm).token1()), result.governanceToken);
        assertEq(ProtocolGovernor(payable(result.governor)).votingDelay(), 1 days);
        assertEq(ProtocolTimelock(payable(result.timelock)).getMinDelay(), 2 days);
        assertEq(UpgradeableInsurancePoolV1(result.upgradeableImplementation).owner(), address(0));
        assertEq(AssemblyBenchmark(result.benchmark).sumSolidity(_sampleArray()), 10);
    }

    function testVerifyDeploymentScriptAcceptsTimelockOwnedConfiguration() public {
        MockClockToken token = new MockClockToken();
        MockGovernorLike governor = new MockGovernorLike(address(token), INITIAL_GOV_SUPPLY);
        MockTimelockLike timelock = new MockTimelockLike();
        MockOwnableLike policyNft = new MockOwnableLike(address(timelock));
        MockOwnableLike insuranceVault = new MockOwnableLike(address(timelock));
        MockOwnableLike insurancePool = new MockOwnableLike(address(timelock));
        MockOwnableLike insuranceFactory = new MockOwnableLike(address(timelock));
        MockRiskRegistryAccess registry = new MockRiskRegistryAccess();

        registry.grantRole(registry.RISK_MANAGER_ROLE(), address(timelock));
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));

        vm.setEnv("PROTOCOL_TIMELOCK", vm.toString(address(timelock)));
        vm.setEnv("PROTOCOL_GOVERNOR", vm.toString(address(governor)));
        vm.setEnv("POLICY_NFT", vm.toString(address(policyNft)));
        vm.setEnv("INSURANCE_VAULT", vm.toString(address(insuranceVault)));
        vm.setEnv("INSURANCE_POOL", vm.toString(address(insurancePool)));
        vm.setEnv("INSURANCE_FACTORY", vm.toString(address(insuranceFactory)));
        vm.setEnv("RISK_REGISTRY", vm.toString(address(registry)));
        vm.setEnv("INITIAL_GOV_SUPPLY", vm.toString(INITIAL_GOV_SUPPLY));

        new VerifyDeployment().run();

        assertEq(registry.hasRole(registry.RISK_MANAGER_ROLE(), address(timelock)), true);
        assertEq(timelock.hasRole(timelock.PROPOSER_ROLE(), address(governor)), true);
    }

    function testUpgradeScriptDeploysV2AndInitializesNewState() public {
        address owner = vm.addr(DEPLOYER_PRIVATE_KEY);
        address collateralAsset = makeAddr("upgrade-collateral");
        UpgradeableInsurancePoolV1 implementationV1 = new UpgradeableInsurancePoolV1();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementationV1),
            abi.encodeCall(UpgradeableInsurancePoolV1.initialize, (owner, collateralAsset))
        );

        vm.setEnv("DEPLOYER_PRIVATE_KEY", vm.toString(DEPLOYER_PRIVATE_KEY));
        vm.setEnv("UPGRADEABLE_POOL_PROXY", vm.toString(address(proxy)));
        vm.setEnv("UPGRADE_MAX_POLICY_DURATION", vm.toString(uint256(730 days)));

        address implementationV2Address = new UpgradeV2().run();
        UpgradeableInsurancePoolV2 upgradedPool = UpgradeableInsurancePoolV2(address(proxy));

        assertEq(UpgradeableInsurancePoolV2(implementationV2Address).version(), "v2");
        assertEq(upgradedPool.version(), "v2");
        assertEq(upgradedPool.maxPolicyDuration(), 730 days);
        assertEq(upgradedPool.owner(), owner);
    }

    function _setDeployEnv(address initialOwner, address collateralAsset) internal {
        vm.setEnv("DEPLOYER_PRIVATE_KEY", vm.toString(DEPLOYER_PRIVATE_KEY));
        vm.setEnv("INITIAL_OWNER", vm.toString(initialOwner));
        vm.setEnv("COLLATERAL_ASSET", vm.toString(collateralAsset));
        vm.setEnv("INITIAL_GOV_SUPPLY", vm.toString(INITIAL_GOV_SUPPLY));
        vm.setEnv("POLICY_BASE_URI", "ipfs://phase5-policy/");
    }

    function _sampleArray() internal pure returns (uint256[] memory values) {
        values = new uint256[](4);
        values[0] = 1;
        values[1] = 2;
        values[2] = 3;
        values[3] = 4;
    }
}
