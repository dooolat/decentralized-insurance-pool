// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
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

contract MockCoverageSource {
    uint256 internal _activeCoverage;

    function setActiveCoverage(uint256 newActiveCoverage) external {
        _activeCoverage = newActiveCoverage;
    }

    function activeCoverage() external view returns (uint256) {
        return _activeCoverage;
    }
}

contract InsuranceVaultTest is Test {
    address internal owner = makeAddr("owner");
    address internal underwriter = makeAddr("underwriter");
    address internal claimManager = makeAddr("claimManager");
    address internal stranger = makeAddr("stranger");

    MockCollateralToken internal collateralToken;
    MockCoverageSource internal coverageSource;
    InsuranceVault internal vault;

    function setUp() public {
        collateralToken = new MockCollateralToken();
        coverageSource = new MockCoverageSource();
        vault = new InsuranceVault(collateralToken, owner, "Insurance Vault Share", "IVS");

        vm.prank(owner);
        vault.setInsurancePool(address(coverageSource));

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

    function testLockedLiquidityTracksInsurancePoolActiveCoverage() public {
        coverageSource.setActiveCoverage(125_000e6);

        assertEq(vault.lockedLiquidity(), 125_000e6);
        assertEq(vault.freeLiquidity(), 375_000e6);
    }

    function testFreeLiquidityReturnsZeroWhenCoverageExceedsAssets() public {
        coverageSource.setActiveCoverage(500_000e6 + 1);

        assertEq(vault.freeLiquidity(), 0);
        assertEq(vault.maxWithdraw(underwriter), 0);
        assertEq(vault.maxRedeem(underwriter), 0);
    }

    function testMaxWithdrawRespectsReservedCoverage() public {
        coverageSource.setActiveCoverage(200_000e6);

        assertEq(vault.maxWithdraw(underwriter), 300_000e6);
    }

    function testWithdrawAboveFreeLiquidityReverts() public {
        coverageSource.setActiveCoverage(300_000e6);

        vm.prank(underwriter);
        vm.expectRevert();
        vault.withdraw(250_001e6, underwriter, underwriter);
    }

    function testRedeemAboveFreeLiquidityReverts() public {
        coverageSource.setActiveCoverage(450_000e6);

        uint256 unsafeShares = vault.previewWithdraw(50_001e6);

        vm.prank(underwriter);
        vm.expectRevert();
        vault.redeem(unsafeShares, underwriter, underwriter);
    }

    function testDecimalsFollowUnderlyingAsset() public view {
        assertEq(vault.decimals(), 6);
    }

    function testOwnerCanUpdateProtocolAddresses() public {
        vm.prank(owner);
        vault.setInsurancePool(stranger);
        vm.prank(owner);
        vault.setClaimManager(claimManager);

        assertEq(vault.insurancePool(), stranger);
        assertEq(vault.claimManager(), claimManager);
    }

    function testProtocolAddressUpdatesRejectInvalidInputs() public {
        vm.prank(owner);
        vm.expectRevert(InsuranceVault.InvalidProtocolAddress.selector);
        vault.setInsurancePool(address(0));

        vm.prank(owner);
        vm.expectRevert(InsuranceVault.InvalidProtocolAddress.selector);
        vault.setClaimManager(address(0));
    }

    function testNonOwnerCannotUpdateProtocolAddresses() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger)
        );
        vault.setInsurancePool(stranger);

        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger)
        );
        vault.setClaimManager(claimManager);
    }

    function testPausedVaultRejectsNewDeposits() public {
        vm.prank(owner);
        vault.pause();

        collateralToken.mint(stranger, 10_000e6);
        vm.prank(stranger);
        collateralToken.approve(address(vault), type(uint256).max);

        vm.prank(stranger);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        vault.deposit(1_000e6, stranger);
    }

    function testClaimManagerCanPayClaimWithinFreeLiquidity() public {
        vm.prank(owner);
        vault.setClaimManager(claimManager);

        uint256 balanceBefore = collateralToken.balanceOf(stranger);
        vm.prank(claimManager);
        vault.payClaim(stranger, 25_000e6);

        assertEq(collateralToken.balanceOf(stranger), balanceBefore + 25_000e6);
        assertEq(vault.totalAssets(), 475_000e6);
    }

    function testPayClaimRejectsUnauthorizedCaller() public {
        vm.prank(stranger);
        vm.expectRevert(InsuranceVault.CallerNotClaimManager.selector);
        vault.payClaim(stranger, 1);
    }

    function testPayClaimRejectsAmountAboveFreeLiquidity() public {
        vm.prank(owner);
        vault.setClaimManager(claimManager);
        coverageSource.setActiveCoverage(490_000e6);

        vm.prank(claimManager);
        vm.expectRevert(
            abi.encodeWithSelector(
                InsuranceVault.ClaimAmountExceedsFreeLiquidity.selector, 20_000e6, 10_000e6
            )
        );
        vault.payClaim(stranger, 20_000e6);
    }
}
