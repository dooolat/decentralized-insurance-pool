// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ProtocolSystemFixture } from "../helpers/ProtocolSystemFixture.sol";
import { InsurancePool } from "../../contracts/insurance/InsurancePool.sol";

contract InsurancePoolTest is ProtocolSystemFixture {
    function testBuyPolicyStoresPolicyAndMintsNft() public {
        (uint256 policyId, InsurancePool.Policy memory policy) =
            _buyPolicy(100_000e6, 30 days);

        assertEq(policyId, 1);
        assertEq(policy.policyId, 1);
        assertEq(policy.buyer, buyer);
        assertEq(policy.riskTypeId, riskTypeId);
        assertEq(uint8(policy.status), uint8(InsurancePool.PolicyStatus.Active));
        assertEq(policyNft.ownerOf(policyId), buyer);
    }

    function testBuyPolicyTransfersPremiumIntoVault() public {
        uint256 assetsBefore = vault.totalAssets();
        uint256 expectedPremium = insurancePool.calculatePremium(riskTypeId, 100_000e6, 30 days);

        _buyPolicy(100_000e6, 30 days);

        assertEq(vault.totalAssets(), assetsBefore + expectedPremium);
    }

    function testBuyPolicyIncreasesCoverageTracking() public {
        _buyPolicy(125_000e6, 30 days);

        assertEq(insurancePool.activeCoverage(), 125_000e6);
        assertEq(insurancePool.activeCoverageByRisk(riskTypeId), 125_000e6);
    }

    function testBuyPolicyRejectsZeroCoverage() public {
        vm.prank(buyer);
        vm.expectRevert(InsurancePool.InvalidCoverageAmount.selector);
        insurancePool.buyPolicy(riskTypeId, 0, 30 days);
    }

    function testBuyPolicyRejectsTooShortDuration() public {
        vm.prank(buyer);
        vm.expectRevert(InsurancePool.InvalidDuration.selector);
        insurancePool.buyPolicy(riskTypeId, 100_000e6, 1 days - 1);
    }

    function testBuyPolicyRejectsTooLongDuration() public {
        vm.prank(buyer);
        vm.expectRevert(InsurancePool.InvalidDuration.selector);
        insurancePool.buyPolicy(riskTypeId, 100_000e6, 366 days);
    }

    function testBuyPolicyRejectsInactiveRiskType() public {
        vm.prank(admin);
        riskRegistry.deactivateRiskType(riskTypeId);

        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(InsurancePool.InactiveRiskType.selector, riskTypeId));
        insurancePool.buyPolicy(riskTypeId, 100_000e6, 30 days);
    }

    function testBuyPolicyRejectsCoverageAboveRiskLimit() public {
        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                InsurancePool.CoverageExceedsRiskLimit.selector, 600_000e6, 500_000e6
            )
        );
        insurancePool.buyPolicy(riskTypeId, 600_000e6, 30 days);
    }

    function testBuyPolicyRejectsCoverageAboveLiquidity() public {
        vm.prank(admin);
        riskRegistry.updateRiskType(
            riskTypeId,
            "STABLECOIN_DEPEG",
            500,
            2_000_000e6,
            address(priceFeed),
            950e8,
            1 days,
            true
        );

        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                InsurancePool.CoverageExceedsLiquidity.selector,
                1_000_001e6,
                1_000_000e6
            )
        );
        insurancePool.buyPolicy(riskTypeId, 1_000_001e6, 30 days);
    }

    function testCalculatePremiumRoundsUpForSmallPolicies() public view {
        uint256 premium = insurancePool.calculatePremium(riskTypeId, 1e6, 1 days);

        assertEq(premium, 137);
    }

    function testExpirePolicyReleasesCoverageAfterEndTime() public {
        (uint256 policyId,) = _buyPolicy(100_000e6, 30 days);

        vm.warp(block.timestamp + 30 days + 1);
        insurancePool.expirePolicy(policyId);

        InsurancePool.Policy memory policy = insurancePool.getPolicy(policyId);
        assertEq(uint8(policy.status), uint8(InsurancePool.PolicyStatus.Expired));
        assertEq(insurancePool.activeCoverage(), 0);
        assertEq(insurancePool.activeCoverageByRisk(riskTypeId), 0);
    }

    function testExpirePolicyRevertsBeforeEndTime() public {
        (uint256 policyId,) = _buyPolicy(100_000e6, 30 days);

        vm.expectRevert(abi.encodeWithSelector(InsurancePool.PolicyNotExpired.selector, policyId));
        insurancePool.expirePolicy(policyId);
    }

    function testOnlyClaimManagerCanMarkPolicyClaimed() public {
        (uint256 policyId,) = _buyPolicy(100_000e6, 30 days);

        vm.expectRevert(InsurancePool.CallerNotClaimManager.selector);
        insurancePool.markPolicyClaimed(policyId);
    }

    function testMarkPolicyClaimedReturnsPayoutAndReleasesCoverage() public {
        (uint256 policyId,) = _buyPolicy(100_000e6, 30 days);

        vm.prank(address(claimManager));
        uint256 payout = insurancePool.markPolicyClaimed(policyId);

        InsurancePool.Policy memory policy = insurancePool.getPolicy(policyId);
        assertEq(payout, 100_000e6);
        assertEq(uint8(policy.status), uint8(InsurancePool.PolicyStatus.Claimed));
        assertEq(insurancePool.activeCoverage(), 0);
    }

    function testGetActivePoliciesReturnsOnlyActivePolicies() public {
        (uint256 firstPolicyId,) = _buyPolicy(100_000e6, 30 days);
        (uint256 secondPolicyId,) = _buyPolicy(50_000e6, 45 days);

        vm.warp(block.timestamp + 30 days + 1);
        insurancePool.expirePolicy(firstPolicyId);

        InsurancePool.Policy[] memory activePolicies = insurancePool.getActivePolicies();
        assertEq(activePolicies.length, 1);
        assertEq(activePolicies[0].policyId, secondPolicyId);
    }

    function testOwnerCanUpdateClaimManager() public {
        vm.prank(admin);
        insurancePool.setClaimManager(operator);

        assertEq(insurancePool.claimManager(), operator);
    }

    function testSetClaimManagerRejectsZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(InsurancePool.InvalidAddress.selector);
        insurancePool.setClaimManager(address(0));
    }

    function testPausedPoolRejectsPolicyPurchase() public {
        vm.prank(admin);
        insurancePool.pause();

        vm.prank(buyer);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        insurancePool.buyPolicy(riskTypeId, 100_000e6, 30 days);
    }

    function testAvailableLiquidityFallsToZeroAtFullCoverage() public {
        uint256 firstPremium = insurancePool.calculatePremium(riskTypeId, 500_000e6, 30 days);
        _buyPolicy(500_000e6, 30 days);

        assertEq(insurancePool.availableLiquidity(), 500_000e6 + firstPremium);

        vm.prank(admin);
        riskRegistry.updateRiskType(
            riskTypeId,
            "STABLECOIN_DEPEG",
            500,
            1_000_000e6,
            address(priceFeed),
            950e8,
            1 days,
            true
        );

        uint256 secondPremium = insurancePool.calculatePremium(riskTypeId, 500_000e6, 31 days);
        _buyPolicy(500_000e6, 31 days);

        assertEq(insurancePool.availableLiquidity(), firstPremium + secondPremium);
    }

    function testGetActivePoliciesReturnsEmptyArrayBeforeSales() public view {
        InsurancePool.Policy[] memory activePolicies = insurancePool.getActivePolicies();
        assertEq(activePolicies.length, 0);
    }

    function testPoolAccessorsReturnExpectedProtocolAddresses() public view {
        assertEq(insurancePool.vault(), address(vault));
        assertEq(insurancePool.policyNFT(), address(policyNft));
        assertEq(insurancePool.riskRegistry(), address(riskRegistry));
    }

    function testExpiringClaimedPolicyRevertsAsInactive() public {
        (uint256 policyId,) = _buyPolicy(100_000e6, 30 days);

        vm.prank(address(claimManager));
        insurancePool.markPolicyClaimed(policyId);

        vm.warp(block.timestamp + 30 days + 1);
        vm.expectRevert(abi.encodeWithSelector(InsurancePool.PolicyNotActive.selector, policyId));
        insurancePool.expirePolicy(policyId);
    }
}
