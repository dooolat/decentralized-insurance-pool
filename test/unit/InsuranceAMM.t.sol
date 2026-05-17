// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { GovernanceToken } from "../../contracts/token/GovernanceToken.sol";
import { InsuranceAMM } from "../../contracts/amm/InsuranceAMM.sol";
import { FixtureCollateralToken } from "../helpers/ProtocolSystemFixture.sol";

contract InsuranceAMMUnitTest is Test {
    address internal owner = makeAddr("owner");
    address internal lpProvider = makeAddr("lpProvider");
    address internal trader = makeAddr("trader");
    address internal recipient = makeAddr("recipient");

    GovernanceToken internal governanceToken;
    FixtureCollateralToken internal collateralToken;
    InsuranceAMM internal amm;

    function setUp() public {
        governanceToken = new GovernanceToken(owner, 1_000_000 ether);
        collateralToken = new FixtureCollateralToken();
        amm = new InsuranceAMM(address(collateralToken), address(governanceToken));

        collateralToken.mint(lpProvider, 2_000_000e6);
        collateralToken.mint(trader, 2_000_000e6);

        vm.prank(owner);
        governanceToken.transfer(lpProvider, 400_000 ether);
        vm.prank(owner);
        governanceToken.transfer(trader, 200_000 ether);

        vm.prank(lpProvider);
        collateralToken.approve(address(amm), type(uint256).max);
        vm.prank(lpProvider);
        governanceToken.approve(address(amm), type(uint256).max);

        vm.prank(trader);
        collateralToken.approve(address(amm), type(uint256).max);
        vm.prank(trader);
        governanceToken.approve(address(amm), type(uint256).max);
    }

    function testConstructorRejectsZeroToken() public {
        vm.expectRevert(InsuranceAMM.InvalidToken.selector);
        new InsuranceAMM(address(0), address(governanceToken));
    }

    function testConstructorRejectsDuplicateTokenAddresses() public {
        vm.expectRevert(InsuranceAMM.InvalidToken.selector);
        new InsuranceAMM(address(collateralToken), address(collateralToken));
    }

    function testInitialAddLiquidityMintsLpTokensAndLocksMinimumLiquidity() public {
        uint256 amount0 = 200_000e6;
        uint256 amount1 = 100_000 ether;
        uint256 expectedLiquidity = Math.sqrt(amount0 * amount1) - amm.MINIMUM_LIQUIDITY();

        vm.prank(lpProvider);
        (uint256 liquidityMinted, uint256 actualAmount0, uint256 actualAmount1) =
            amm.addLiquidity(amount0, amount1);

        assertEq(liquidityMinted, expectedLiquidity);
        assertEq(actualAmount0, amount0);
        assertEq(actualAmount1, amount1);
        assertEq(amm.balanceOf(lpProvider), expectedLiquidity);
        assertEq(amm.balanceOf(address(1)), amm.MINIMUM_LIQUIDITY());
    }

    function testAddLiquidityUsesPoolRatioAfterBootstrap() public {
        vm.prank(lpProvider);
        amm.addLiquidity(200_000e6, 100_000 ether);

        collateralToken.mint(recipient, 100_000e6);
        vm.prank(owner);
        governanceToken.transfer(recipient, 100_000 ether);
        vm.prank(recipient);
        collateralToken.approve(address(amm), type(uint256).max);
        vm.prank(recipient);
        governanceToken.approve(address(amm), type(uint256).max);

        vm.prank(recipient);
        (uint256 liquidityMinted, uint256 amount0Used, uint256 amount1Used) =
            amm.addLiquidity(50_000e6, 40_000 ether);

        assertGt(liquidityMinted, 0);
        assertEq(amount0Used, 50_000e6);
        assertEq(amount1Used, 25_000 ether);
    }

    function testAddLiquidityRejectsZeroAmounts() public {
        vm.prank(lpProvider);
        vm.expectRevert(InsuranceAMM.InvalidAmount.selector);
        amm.addLiquidity(0, 100_000 ether);
    }

    function testRemoveLiquidityReturnsUnderlyingAssets() public {
        vm.prank(lpProvider);
        (uint256 liquidityMinted,,) = amm.addLiquidity(200_000e6, 100_000 ether);

        uint256 collateralBefore = collateralToken.balanceOf(lpProvider);
        uint256 governanceBefore = governanceToken.balanceOf(lpProvider);
        uint256 burnAmount = liquidityMinted / 2;

        vm.prank(lpProvider);
        (uint256 amount0Out, uint256 amount1Out) = amm.removeLiquidity(burnAmount);

        assertGt(amount0Out, 0);
        assertGt(amount1Out, 0);
        assertEq(collateralToken.balanceOf(lpProvider), collateralBefore + amount0Out);
        assertEq(governanceToken.balanceOf(lpProvider), governanceBefore + amount1Out);
        assertEq(amm.balanceOf(lpProvider), liquidityMinted - burnAmount);
    }

    function testSwapExactInputTransfersOutputToRecipient() public {
        vm.prank(lpProvider);
        amm.addLiquidity(200_000e6, 100_000 ether);

        (uint112 reserve0, uint112 reserve1) = amm.getReserves();
        uint256 expectedOut = amm.getAmountOut(10_000e6, reserve0, reserve1);

        uint256 balanceBefore = governanceToken.balanceOf(recipient);
        vm.prank(trader);
        uint256 amountOut =
            amm.swapExactInput(address(collateralToken), 10_000e6, 1, recipient);

        assertEq(amountOut, expectedOut);
        assertEq(governanceToken.balanceOf(recipient), balanceBefore + expectedOut);
    }

    function testSwapRevertsWhenMinOutTooHigh() public {
        vm.prank(lpProvider);
        amm.addLiquidity(200_000e6, 100_000 ether);

        (uint112 reserve0, uint112 reserve1) = amm.getReserves();
        uint256 expectedOut = amm.getAmountOut(10_000e6, reserve0, reserve1);

        vm.prank(trader);
        vm.expectRevert(
            abi.encodeWithSelector(
                InsuranceAMM.SlippageExceeded.selector, expectedOut, expectedOut + 1
            )
        );
        amm.swapExactInput(address(collateralToken), 10_000e6, expectedOut + 1, trader);
    }

    function testSwapRejectsZeroAmount() public {
        vm.prank(lpProvider);
        amm.addLiquidity(200_000e6, 100_000 ether);

        vm.prank(trader);
        vm.expectRevert(InsuranceAMM.InvalidAmount.selector);
        amm.swapExactInput(address(collateralToken), 0, 0, trader);
    }

    function testSwapRejectsInvalidToken() public {
        vm.prank(lpProvider);
        amm.addLiquidity(200_000e6, 100_000 ether);

        vm.prank(trader);
        vm.expectRevert(InsuranceAMM.InvalidToken.selector);
        amm.swapExactInput(makeAddr("badToken"), 1, 0, trader);
    }
}
