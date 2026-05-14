// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract InsuranceVault is ERC20, ERC4626, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error ReservedCoverageExceedsAssets(uint256 reservedCoverage, uint256 totalAssetsAvailable);
    error WithdrawalExceedsFreeLiquidity(uint256 requested, uint256 freeLiquidityAvailable);

    uint256 public reservedCoverage;

    event ReservedCoverageUpdated(uint256 previousReservedCoverage, uint256 newReservedCoverage);

    constructor(
        IERC20 asset_,
        address initialOwner,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) ERC4626(asset_) Ownable(initialOwner) { }

    function setReservedCoverage(
        uint256 newReservedCoverage
    ) external onlyOwner {
        uint256 totalAssetBalance = totalAssets();
        if (newReservedCoverage > totalAssetBalance) {
            revert ReservedCoverageExceedsAssets(newReservedCoverage, totalAssetBalance);
        }

        emit ReservedCoverageUpdated(reservedCoverage, newReservedCoverage);
        reservedCoverage = newReservedCoverage;
    }

    function freeLiquidity() public view returns (uint256) {
        uint256 totalAssetBalance = totalAssets();
        if (reservedCoverage >= totalAssetBalance) {
            return 0;
        }

        return totalAssetBalance - reservedCoverage;
    }

    function maxWithdraw(
        address owner
    ) public view override returns (uint256) {
        return Math.min(super.maxWithdraw(owner), freeLiquidity());
    }

    function maxRedeem(
        address owner
    ) public view override returns (uint256) {
        return Math.min(super.maxRedeem(owner), convertToShares(freeLiquidity()));
    }

    function decimals() public view override(ERC20, ERC4626) returns (uint8) {
        return super.decimals();
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public override nonReentrant returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function mint(
        uint256 shares,
        address receiver
    ) public override nonReentrant returns (uint256) {
        return super.mint(shares, receiver);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override nonReentrant returns (uint256) {
        uint256 freeLiquidityAvailable = freeLiquidity();
        if (assets > freeLiquidityAvailable) {
            revert WithdrawalExceedsFreeLiquidity(assets, freeLiquidityAvailable);
        }

        return super.withdraw(assets, receiver, owner);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override nonReentrant returns (uint256) {
        uint256 assets = previewRedeem(shares);
        uint256 freeLiquidityAvailable = freeLiquidity();
        if (assets > freeLiquidityAvailable) {
            revert WithdrawalExceedsFreeLiquidity(assets, freeLiquidityAvailable);
        }

        return super.redeem(shares, receiver, owner);
    }
}
