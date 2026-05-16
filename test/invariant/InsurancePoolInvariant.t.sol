// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { StdInvariant } from "forge-std/StdInvariant.sol";
import { BaseProtocolTest } from "../helpers/BaseProtocolTest.sol";
import { IInsurancePool } from "../../contracts/interfaces/IInsurancePool.sol";

contract InsurancePoolInvariantHandler is BaseProtocolTest {
    uint256[] internal trackedPolicyIds;
    mapping(uint256 policyId => uint256 count) internal successfulClaimCount;

    function deposit(
        uint96 amount,
        uint8 actorSeed
    ) external {
        address actor = actorSeed % 2 == 0 ? underwriter : secondaryTrader;
        amount = uint96(bound(uint256(amount), 1, 100_000 * 1e6));

        vm.prank(owner);
        collateralToken.mint(actor, amount);
        vm.prank(actor);
        collateralToken.approve(address(vault), type(uint256).max);

        vm.prank(actor);
        try vault.deposit(amount, actor) { } catch { }
    }

    function buyPolicy(
        uint96 coverageAmount,
        uint32 durationDays,
        uint8 actorSeed
    ) external {
        address actor = actorSeed % 2 == 0 ? buyer : trader;
        coverageAmount = uint96(bound(uint256(coverageAmount), 1e6, 50_000 * 1e6));
        durationDays = uint32(bound(uint256(durationDays), 1, 365));

        vm.prank(actor);
        collateralToken.approve(address(insurancePool), type(uint256).max);

        vm.prank(actor);
        try insurancePool.buyPolicy(riskTypeId, coverageAmount, uint256(durationDays) * 1 days) returns (
            uint256 policyId
        ) {
            trackedPolicyIds.push(policyId);
        } catch { }
    }

    function warpTime(
        uint32 jumpSeconds
    ) external {
        jumpSeconds = uint32(bound(uint256(jumpSeconds), 1 hours, 40 days));
        vm.warp(block.timestamp + jumpSeconds);
    }

    function expirePolicy(
        uint8 seed
    ) external {
        if (trackedPolicyIds.length == 0) return;
        uint256 policyId = trackedPolicyIds[seed % trackedPolicyIds.length];
        try insurancePool.expirePolicy(policyId) { } catch { }
    }

    function setClaimPrice(
        bool eligible
    ) external {
        priceFeed.updateAnswer(eligible ? int256(900e8) : int256(1000e8));
    }

    function executeClaim(
        uint8 seed
    ) external {
        if (trackedPolicyIds.length == 0) return;
        uint256 policyId = trackedPolicyIds[seed % trackedPolicyIds.length];
        IInsurancePool.Policy memory policy = insurancePool.getPolicy(policyId);
        if (policy.policyId == 0) return;

        vm.prank(policy.buyer);
        try claimManager.executeClaim(policyId) returns (bool paid, uint256) {
            if (paid) {
                successfulClaimCount[policyId] += 1;
            }
        } catch { }
    }

    function trackedPolicyCount() external view returns (uint256) {
        return trackedPolicyIds.length;
    }

    function trackedPolicyIdAt(
        uint256 index
    ) external view returns (uint256) {
        return trackedPolicyIds[index];
    }

    function successfulClaimsFor(
        uint256 policyId
    ) external view returns (uint256) {
        return successfulClaimCount[policyId];
    }

    function vaultTotalAssets() external view returns (uint256) {
        return vault.totalAssets();
    }

    function vaultTokenBalance() external view returns (uint256) {
        return collateralToken.balanceOf(address(vault));
    }

    function poolActiveCoverage() external view returns (uint256) {
        return insurancePool.activeCoverage();
    }

    function poolAvailableLiquidity() external view returns (uint256) {
        return insurancePool.availableLiquidity();
    }

    function activeCoverageForRisk() external view returns (uint256) {
        return insurancePool.activeCoverageByRisk(riskTypeId);
    }

    function maxCoverageForRisk() external view returns (uint256) {
        return riskRegistry.getRiskType(riskTypeId).maxCoverage;
    }
}

contract InsurancePoolInvariantTest is StdInvariant, BaseProtocolTest {
    InsurancePoolInvariantHandler internal handler;

    function setUp() public override {
        handler = new InsurancePoolInvariantHandler();
        handler.setUp();
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = handler.deposit.selector;
        selectors[1] = handler.buyPolicy.selector;
        selectors[2] = handler.warpTime.selector;
        selectors[3] = handler.expirePolicy.selector;
        selectors[4] = handler.setClaimPrice.selector;
        selectors[5] = handler.executeClaim.selector;
        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
    }

    function invariantVaultAssetsMirrorTokenBalance() public view {
        assertEq(handler.vaultTotalAssets(), handler.vaultTokenBalance());
    }

    function invariantNoDoubleClaimPayout() public view {
        uint256 policyCount = handler.trackedPolicyCount();
        for (uint256 index; index < policyCount; ++index) {
            uint256 policyId = handler.trackedPolicyIdAt(index);
            assertLe(handler.successfulClaimsFor(policyId), 1);
        }
    }

    function invariantActiveCoverageNeverExceedsVaultBackstop() public view {
        assertLe(handler.poolActiveCoverage(), handler.vaultTotalAssets());
    }

    function invariantRiskExposureNeverExceedsConfiguredLimit() public view {
        assertLe(handler.activeCoverageForRisk(), handler.maxCoverageForRisk());
    }

    function invariantAvailableLiquidityNeverUnderflows() public view {
        assertLe(handler.poolAvailableLiquidity(), handler.vaultTotalAssets());
    }
}
