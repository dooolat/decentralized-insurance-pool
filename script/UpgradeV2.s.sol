// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { UpgradeableInsurancePoolV1 } from "../contracts/upgrade/UpgradeableInsurancePoolV1.sol";
import { UpgradeableInsurancePoolV2 } from "../contracts/upgrade/UpgradeableInsurancePoolV2.sol";

contract UpgradeV2 is Script {
    function run() external returns (address implementationV2) {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address proxyAddress = vm.envAddress("UPGRADEABLE_POOL_PROXY");
        uint256 maxPolicyDuration = vm.envOr("UPGRADE_MAX_POLICY_DURATION", uint256(365 days));

        vm.startBroadcast(deployerPrivateKey);

        UpgradeableInsurancePoolV2 upgradedImplementation = new UpgradeableInsurancePoolV2();
        UpgradeableInsurancePoolV1(proxyAddress).upgradeToAndCall(
            address(upgradedImplementation),
            abi.encodeCall(UpgradeableInsurancePoolV2.initializeV2, (maxPolicyDuration))
        );

        vm.stopBroadcast();
        return address(upgradedImplementation);
    }
}
