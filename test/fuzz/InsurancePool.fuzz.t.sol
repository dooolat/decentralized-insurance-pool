// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ProtocolSystemFixture } from "../helpers/ProtocolSystemFixture.sol";
import { InsurancePool } from "../../contracts/insurance/InsurancePool.sol";

contract InsurancePoolFuzzTest is ProtocolSystemFixture {
    function testFuzzCalculatePremiumReturnsPositiveAmount(
        uint96 coverageAmount,
        uint32 durationDays
    ) public view {
        coverageAmount = uint96(bound(uint256(coverageAmount), 1e6, 250_000e6));
        durationDays = uint32(bound(uint256(durationDays), 1, 365));

        uint256 premium =
            insurancePool.calculatePremium(riskTypeId, coverageAmount, uint256(durationDays) * 1 days);

        assertGt(premium, 0);
    }

    function testFuzzBuyPolicyTracksCoverage(
        uint96 coverageAmount,
        uint32 durationDays
    ) public {
        coverageAmount = uint96(bound(uint256(coverageAmount), 1e6, 250_000e6));
        durationDays = uint32(bound(uint256(durationDays), 1, 365));

        (uint256 policyId, InsurancePool.Policy memory policy) =
            _buyPolicy(coverageAmount, uint256(durationDays) * 1 days);

        assertEq(policyId, 1);
        assertEq(policy.coverageAmount, coverageAmount);
        assertEq(insurancePool.activeCoverage(), coverageAmount);
        assertEq(insurancePool.activeCoverageByRisk(riskTypeId), coverageAmount);
    }

    function testFuzzClaimPayoutMatchesCoverageWhenTriggered(
        uint96 coverageAmount
    ) public {
        coverageAmount = uint96(bound(uint256(coverageAmount), 1e6, 200_000e6));
        (uint256 policyId,) = _buyPolicy(coverageAmount, 30 days);
        uint256 buyerBalanceBefore = collateralToken.balanceOf(buyer);
        _setPrice(int256(900e8));

        vm.prank(buyer);
        (bool paid, uint256 payoutAmount) = claimManager.executeClaim(policyId);

        assertTrue(paid);
        assertEq(payoutAmount, coverageAmount);
        assertEq(collateralToken.balanceOf(buyer), buyerBalanceBefore + coverageAmount);
    }

    function testFuzzExpirePolicyReleasesCoverage(
        uint96 coverageAmount,
        uint32 durationDays
    ) public {
        coverageAmount = uint96(bound(uint256(coverageAmount), 1e6, 250_000e6));
        durationDays = uint32(bound(uint256(durationDays), 1, 365));

        (uint256 policyId,) = _buyPolicy(coverageAmount, uint256(durationDays) * 1 days);

        vm.warp(block.timestamp + uint256(durationDays) * 1 days + 1);
        insurancePool.expirePolicy(policyId);

        assertEq(insurancePool.activeCoverage(), 0);
        assertEq(insurancePool.activeCoverageByRisk(riskTypeId), 0);
    }
}
