// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { InsuranceVault } from "../../contracts/vault/InsuranceVault.sol";

contract MockCollateralToken is ERC20 {
    constructor() ERC20("Mock USDC", "mUSDC") { }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract InsuranceVaultTest is Test {
    address internal owner = makeAddr("owner");
    address internal underwriter = makeAddr("underwriter");

    MockCollateralToken internal collateralToken;
    InsuranceVault internal vault;

    function setUp() public {
        collateralToken = new MockCollateralToken();
        vault = new InsuranceVault(collateralToken, owner, "Insurance Vault Share", "IVS");

        collateralToken.mint(underwriter, 1_000_000e6);

        vm.startPrank(underwriter);
        collateralToken.approve(address(vault), type(uint256).max);
        vault.deposit(500_000e6, underwriter);
        vm.stopPrank();
    }

    function testInitialDepositMintsVaultShares() public view {
        assertEq(vault.totalAssets(), 500_000e6);
        assertEq(vault.balanceOf(underwriter), 500_000e6);
    }

    function testFreeLiquidityMatchesAssetsWhenNothingReserved() public view {
        assertEq(vault.freeLiquidity(), 500_000e6);
    }

    function testOwnerCanReserveCoverage() public {
        vm.prank(owner);
        vault.setReservedCoverage(125_000e6);

        assertEq(vault.reservedCoverage(), 125_000e6);
        assertEq(vault.freeLiquidity(), 375_000e6);
    }

    function testReserveCoverageAboveAssetsReverts() public {
        vm.prank(owner);
        vm.expectRevert();
        vault.setReservedCoverage(500_000e6 + 1);
    }

    function testMaxWithdrawRespectsReservedCoverage() public {
        vm.prank(owner);
        vault.setReservedCoverage(200_000e6);

        assertEq(vault.maxWithdraw(underwriter), 300_000e6);
    }

    function testWithdrawAboveFreeLiquidityReverts() public {
        vm.prank(owner);
        vault.setReservedCoverage(300_000e6);

        vm.prank(underwriter);
        vm.expectRevert();
        vault.withdraw(250_001e6, underwriter, underwriter);
    }

    function testRedeemAboveFreeLiquidityReverts() public {
        vm.prank(owner);
        vault.setReservedCoverage(450_000e6);

        uint256 unsafeShares = vault.previewWithdraw(50_001e6);

        vm.prank(underwriter);
        vm.expectRevert();
        vault.redeem(unsafeShares, underwriter, underwriter);
    }

    function testDecimalsFollowUnderlyingAsset() public view {
        assertEq(vault.decimals(), 6);
    }
}
