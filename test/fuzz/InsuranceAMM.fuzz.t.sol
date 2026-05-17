// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { BaseProtocolTest } from "../helpers/BaseProtocolTest.sol";

contract InsuranceAMMFuzzTest is BaseProtocolTest {
    function testFuzzSwapMaintainsNonDecreasingK(
        uint96 amountIn
    ) public {
        _addDefaultAmmLiquidity();
        amountIn = uint96(bound(uint256(amountIn), 1e6, 10_000 * 1e6));

        (uint112 reserve0Before, uint112 reserve1Before) = insuranceAmm.getReserves();
        uint256 kBefore = uint256(reserve0Before) * uint256(reserve1Before);

        vm.prank(trader);
        insuranceAmm.swapExactInput(address(collateralToken), amountIn, 1, trader);

        (uint112 reserve0After, uint112 reserve1After) = insuranceAmm.getReserves();
        uint256 kAfter = uint256(reserve0After) * uint256(reserve1After);
        assertGe(kAfter, kBefore);
    }

    function testFuzzAddLiquidityMintsLpTokens(
        uint96 collateralAmount,
        uint96 governanceAmount
    ) public {
        collateralAmount = uint96(bound(uint256(collateralAmount), 1e6, 25_000 * 1e6));
        governanceAmount = uint96(bound(uint256(governanceAmount), 1 ether, 20_000 ether));

        vm.prank(lpProvider);
        (uint256 liquidityMinted,,) =
            insuranceAmm.addLiquidity(collateralAmount, governanceAmount);

        assertGt(liquidityMinted, 0);
        assertEq(insuranceAmm.balanceOf(lpProvider), liquidityMinted);
    }

    function testFuzzSwapRevertsWhenMinOutTooHigh(
        uint96 amountIn
    ) public {
        _addDefaultAmmLiquidity();
        amountIn = uint96(bound(uint256(amountIn), 1e6, 10_000 * 1e6));

        (uint112 reserve0, uint112 reserve1) = insuranceAmm.getReserves();
        uint256 expectedOut = insuranceAmm.getAmountOut(amountIn, reserve0, reserve1);

        vm.prank(trader);
        vm.expectRevert();
        insuranceAmm.swapExactInput(
            address(collateralToken),
            amountIn,
            expectedOut + 1,
            trader
        );
    }
}
