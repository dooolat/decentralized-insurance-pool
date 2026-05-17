// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ProtocolSystemFixture } from "../helpers/ProtocolSystemFixture.sol";
import { InsurancePool } from "../../contracts/insurance/InsurancePool.sol";
import { ClaimManager } from "../../contracts/insurance/ClaimManager.sol";
import { ChainlinkOracleAdapter } from "../../contracts/oracle/ChainlinkOracleAdapter.sol";

contract ClaimManagerTest is ProtocolSystemFixture {
    function testExecuteClaimPaysBuyerWhenTriggerConditionIsMet() public {
        (uint256 policyId,) = _buyPolicy(100_000e6, 30 days);
        uint256 buyerBalanceBefore = collateralToken.balanceOf(buyer);
        _setPrice(int256(900e8));

        vm.prank(buyer);
        (bool paid, uint256 payoutAmount) = claimManager.executeClaim(policyId);

        InsurancePool.Policy memory policy = insurancePool.getPolicy(policyId);
        assertTrue(paid);
        assertEq(payoutAmount, 100_000e6);
        assertEq(collateralToken.balanceOf(buyer), buyerBalanceBefore + 100_000e6);
        assertEq(uint8(policy.status), uint8(InsurancePool.PolicyStatus.Claimed));
    }

    function testExecuteClaimReturnsFalseWhenTriggerConditionIsNotMet() public {
        (uint256 policyId,) = _buyPolicy(100_000e6, 30 days);
        _setPrice(int256(1_050e8));

        vm.prank(buyer);
        (bool paid, uint256 payoutAmount) = claimManager.executeClaim(policyId);

        InsurancePool.Policy memory policy = insurancePool.getPolicy(policyId);
        assertFalse(paid);
        assertEq(payoutAmount, 0);
        assertEq(uint8(policy.status), uint8(InsurancePool.PolicyStatus.Active));
    }

    function testExecuteClaimRejectsCallerWithoutPolicyControl() public {
        (uint256 policyId,) = _buyPolicy(100_000e6, 30 days);
        _setPrice(int256(900e8));

        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(
                ClaimManager.NotPolicyOwnerOrApproved.selector, policyId, stranger
            )
        );
        claimManager.executeClaim(policyId);
    }

    function testApprovedOperatorCanExecuteClaim() public {
        (uint256 policyId,) = _buyPolicy(100_000e6, 30 days);
        _setPrice(int256(900e8));

        vm.prank(buyer);
        policyNft.approve(operator, policyId);

        vm.prank(operator);
        (bool paid, uint256 payoutAmount) = claimManager.executeClaim(policyId);

        assertTrue(paid);
        assertEq(payoutAmount, 100_000e6);
    }

    function testExecuteClaimRejectsExpiredPolicies() public {
        (uint256 policyId,) = _buyPolicy(100_000e6, 30 days);

        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(ClaimManager.PolicyAlreadyEnded.selector, policyId));
        claimManager.executeClaim(policyId);
    }

    function testExecuteClaimRejectsAlreadyClaimedPolicy() public {
        (uint256 policyId,) = _buyPolicy(100_000e6, 30 days);
        _setPrice(int256(900e8));

        vm.prank(buyer);
        claimManager.executeClaim(policyId);

        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(ClaimManager.PolicyNotActive.selector, policyId));
        claimManager.executeClaim(policyId);
    }

    function testIsClaimEligibleReturnsTrueWhenPriceCrossesTrigger() public {
        (uint256 policyId,) = _buyPolicy(100_000e6, 30 days);
        _setPrice(int256(900e8));

        (bool eligible, uint256 latestPrice, uint256 triggerThreshold, uint256 updatedAt) =
            claimManager.isClaimEligible(policyId);

        assertTrue(eligible);
        assertEq(latestPrice, 900e8);
        assertEq(triggerThreshold, 950e8);
        assertEq(updatedAt, block.timestamp);
    }

    function testIsClaimEligibleReturnsFalseWhenPolicyExpired() public {
        (uint256 policyId,) = _buyPolicy(100_000e6, 30 days);

        vm.warp(block.timestamp + 30 days + 1);
        (bool eligible, uint256 latestPrice, uint256 triggerThreshold, uint256 updatedAt) =
            claimManager.isClaimEligible(policyId);

        assertFalse(eligible);
        assertEq(latestPrice, 0);
        assertEq(triggerThreshold, 0);
        assertEq(updatedAt, 0);
    }

    function testIsClaimEligibleReturnsFalseWhenPolicyAlreadyClaimed() public {
        (uint256 policyId,) = _buyPolicy(100_000e6, 30 days);
        _setPrice(int256(900e8));

        vm.prank(buyer);
        claimManager.executeClaim(policyId);

        (bool eligible, uint256 latestPrice, uint256 triggerThreshold, uint256 updatedAt) =
            claimManager.isClaimEligible(policyId);

        assertFalse(eligible);
        assertEq(latestPrice, 0);
        assertEq(triggerThreshold, 0);
        assertEq(updatedAt, 0);
    }

    function testExecuteClaimRevertsWhenOraclePriceIsStale() public {
        (uint256 policyId,) = _buyPolicy(100_000e6, 30 days);
        vm.warp(3 days);
        _setStalePrice(int256(900e8), 2 days);

        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                ChainlinkOracleAdapter.StaleOraclePrice.selector,
                address(priceFeed),
                1 days,
                block.timestamp,
                1 days
            )
        );
        claimManager.executeClaim(policyId);
    }
}
