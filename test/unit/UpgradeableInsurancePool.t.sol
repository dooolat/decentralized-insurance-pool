// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UpgradeableInsurancePoolV1 } from "../../contracts/upgrade/UpgradeableInsurancePoolV1.sol";
import { UpgradeableInsurancePoolV2 } from "../../contracts/upgrade/UpgradeableInsurancePoolV2.sol";

contract UpgradeableInsurancePoolTest is Test {
    address internal owner = makeAddr("owner");
    address internal stranger = makeAddr("stranger");
    address internal collateralAsset = makeAddr("collateralAsset");

    UpgradeableInsurancePoolV1 internal implementationV1;
    UpgradeableInsurancePoolV2 internal implementationV2;
    UpgradeableInsurancePoolV1 internal poolV1;

    function setUp() public {
        implementationV1 = new UpgradeableInsurancePoolV1();

        bytes memory initData =
            abi.encodeCall(UpgradeableInsurancePoolV1.initialize, (owner, collateralAsset));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementationV1), initData);
        poolV1 = UpgradeableInsurancePoolV1(address(proxy));
    }

    function testInitializeSetsOwnerAndCollateralAsset() public view {
        assertEq(OwnableUpgradeable(address(poolV1)).owner(), owner);
        assertEq(poolV1.collateralAsset(), collateralAsset);
        assertEq(poolV1.version(), "v1");
    }

    function testInitializeRejectsZeroAddresses() public {
        bytes memory initData =
            abi.encodeCall(UpgradeableInsurancePoolV1.initialize, (address(0), collateralAsset));

        vm.expectRevert(UpgradeableInsurancePoolV1.InvalidAddress.selector);
        new ERC1967Proxy(address(implementationV1), initData);
    }

    function testRecordSyntheticPolicyTracksTotals() public {
        vm.prank(owner);
        poolV1.recordSyntheticPolicy(125_000e6);
        vm.prank(owner);
        poolV1.recordSyntheticPolicy(25_000e6);

        assertEq(poolV1.totalCoveredAmount(), 150_000e6);
        assertEq(poolV1.totalPoliciesSold(), 2);
    }

    function testRecordSyntheticPolicyRejectsNonOwner() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, stranger)
        );
        poolV1.recordSyntheticPolicy(1);
    }

    function testUpgradeToV2ChangesVersionAndInitializesNewState() public {
        implementationV2 = new UpgradeableInsurancePoolV2();

        vm.prank(owner);
        UpgradeableInsurancePoolV1(address(poolV1)).upgradeToAndCall(
            address(implementationV2),
            abi.encodeCall(UpgradeableInsurancePoolV2.initializeV2, (90 days))
        );

        UpgradeableInsurancePoolV2 poolV2 = UpgradeableInsurancePoolV2(address(poolV1));
        assertEq(poolV2.version(), "v2");
        assertEq(poolV2.maxPolicyDuration(), 90 days);
    }

    function testSetMaxPolicyDurationRejectsNonOwnerAfterUpgrade() public {
        implementationV2 = new UpgradeableInsurancePoolV2();

        vm.prank(owner);
        UpgradeableInsurancePoolV1(address(poolV1)).upgradeToAndCall(
            address(implementationV2),
            abi.encodeCall(UpgradeableInsurancePoolV2.initializeV2, (30 days))
        );

        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, stranger)
        );
        UpgradeableInsurancePoolV2(address(poolV1)).setMaxPolicyDuration(180 days);
    }

    function testOwnerCanUpdateMaxPolicyDurationAfterUpgrade() public {
        implementationV2 = new UpgradeableInsurancePoolV2();

        vm.prank(owner);
        UpgradeableInsurancePoolV1(address(poolV1)).upgradeToAndCall(
            address(implementationV2),
            abi.encodeCall(UpgradeableInsurancePoolV2.initializeV2, (30 days))
        );

        vm.prank(owner);
        UpgradeableInsurancePoolV2(address(poolV1)).setMaxPolicyDuration(180 days);

        assertEq(UpgradeableInsurancePoolV2(address(poolV1)).maxPolicyDuration(), 180 days);
    }
}
