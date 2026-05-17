// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { BaseProtocolTest } from "../helpers/BaseProtocolTest.sol";

contract InsuranceVaultFuzzTest is BaseProtocolTest {
    function testFuzzDepositMintsExpectedShares(
        uint96 amount
    ) public {
        amount = uint96(bound(uint256(amount), 1, 250_000 * 1e6));

        vm.prank(owner);
        collateralToken.mint(secondaryTrader, amount);
        vm.prank(secondaryTrader);
        collateralToken.approve(address(vault), type(uint256).max);

        uint256 expectedShares = vault.previewDeposit(amount);
        vm.prank(secondaryTrader);
        uint256 mintedShares = vault.deposit(amount, secondaryTrader);

        assertEq(mintedShares, expectedShares);
    }

    function testFuzzWithdrawWithinFreeLiquiditySucceeds(
        uint96 amount
    ) public {
        _buyDefaultPolicy();
        uint256 maxAssets = vault.maxWithdraw(underwriter);
        amount = uint96(bound(uint256(amount), 1, maxAssets == 0 ? 1 : maxAssets));

        uint256 balanceBefore = collateralToken.balanceOf(underwriter);
        vm.prank(underwriter);
        vault.withdraw(amount, underwriter, underwriter);

        assertEq(collateralToken.balanceOf(underwriter), balanceBefore + amount);
    }

    function testFuzzWithdrawBeyondFreeLiquidityReverts(
        uint96 overflowAmount
    ) public {
        _buyDefaultPolicy();
        uint256 maxAssets = vault.maxWithdraw(underwriter);
        overflowAmount = uint96(bound(uint256(overflowAmount), 1, 50_000 * 1e6));

        vm.prank(underwriter);
        vm.expectRevert();
        vault.withdraw(maxAssets + overflowAmount, underwriter, underwriter);
    }
}
