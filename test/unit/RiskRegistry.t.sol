// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { RiskRegistry } from "../../contracts/insurance/RiskRegistry.sol";

contract RiskRegistryTest is Test {
    address internal admin = makeAddr("admin");
    address internal manager = makeAddr("manager");
    address internal stranger = makeAddr("stranger");

    RiskRegistry internal registry;

    function setUp() public {
        registry = new RiskRegistry(admin);

        vm.prank(admin);
        registry.grantRole(registry.RISK_MANAGER_ROLE(), manager);
    }

    function testAdminStartsWithManagerRole() public view {
        assertTrue(registry.hasRole(registry.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(registry.hasRole(registry.RISK_MANAGER_ROLE(), admin));
        assertTrue(registry.hasRole(registry.RISK_MANAGER_ROLE(), manager));
    }

    function testManagerCanAddRiskType() public {
        vm.prank(manager);
        uint256 riskTypeId = registry.addRiskType(
            "STABLECOIN_DEPEG", 150, 250_000e6, makeAddr("feed"), 97e16, 1 days
        );

        RiskRegistry.RiskType memory riskType = registry.getRiskType(riskTypeId);
        assertEq(riskTypeId, 1);
        assertEq(riskType.name, "STABLECOIN_DEPEG");
        assertEq(riskType.premiumRateBps, 150);
        assertEq(riskType.maxCoverage, 250_000e6);
        assertEq(riskType.stalenessLimit, 1 days);
        assertTrue(riskType.active);
    }

    function testUpdateRiskTypeChangesStoredValues() public {
        vm.prank(manager);
        uint256 riskTypeId =
            registry.addRiskType("ASSET_PRICE_DROP", 200, 100_000e6, makeAddr("feed"), 90e16, 6 hours);

        vm.prank(manager);
        registry.updateRiskType(
            riskTypeId,
            "ASSET_PRICE_DROP_V2",
            225,
            150_000e6,
            makeAddr("newFeed"),
            88e16,
            12 hours,
            true
        );

        RiskRegistry.RiskType memory riskType = registry.getRiskType(riskTypeId);
        assertEq(riskType.name, "ASSET_PRICE_DROP_V2");
        assertEq(riskType.premiumRateBps, 225);
        assertEq(riskType.maxCoverage, 150_000e6);
        assertEq(riskType.stalenessLimit, 12 hours);
    }

    function testDeactivateRiskTypeMarksItInactive() public {
        vm.prank(manager);
        uint256 riskTypeId =
            registry.addRiskType("LIQUIDATION_EVENT", 90, 50_000e6, makeAddr("feed"), 1, 1 hours);

        vm.prank(manager);
        registry.deactivateRiskType(riskTypeId);

        RiskRegistry.RiskType memory riskType = registry.getRiskType(riskTypeId);
        assertFalse(riskType.active);
    }

    function testUnauthorizedAccountCannotAddRiskType() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControl.AccessControlUnauthorizedAccount.selector,
                stranger,
                registry.RISK_MANAGER_ROLE()
            )
        );
        registry.addRiskType("BAD", 100, 100e6, makeAddr("feed"), 1, 1);
    }

    function testInvalidPremiumRateReverts() public {
        vm.prank(manager);
        vm.expectRevert(RiskRegistry.InvalidPremiumRate.selector);
        registry.addRiskType("BAD", 0, 100e6, makeAddr("feed"), 1, 1);
    }

    function testInvalidCoverageLimitReverts() public {
        vm.prank(manager);
        vm.expectRevert(RiskRegistry.InvalidCoverageLimit.selector);
        registry.addRiskType("BAD", 100, 0, makeAddr("feed"), 1, 1);
    }

    function testInvalidOracleFeedReverts() public {
        vm.prank(manager);
        vm.expectRevert(RiskRegistry.InvalidOracleFeed.selector);
        registry.addRiskType("BAD", 100, 100e6, address(0), 1, 1);
    }

    function testMissingRiskTypeReverts() public {
        vm.expectRevert(abi.encodeWithSelector(RiskRegistry.RiskTypeNotFound.selector, 1));
        registry.getRiskType(1);
    }
}
