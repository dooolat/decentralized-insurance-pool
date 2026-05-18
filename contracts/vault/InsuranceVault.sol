// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

interface IInsurancePoolCoverageSource {
    function activeCoverage() external view returns (uint256);
}

contract InsuranceVault is ERC20, ERC4626, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error InvalidProtocolAddress();
    error CallerNotClaimManager();
    error ClaimAmountExceedsFreeLiquidity(uint256 requested, uint256 freeLiquidityAvailable);
    error WithdrawalExceedsFreeLiquidity(uint256 requested, uint256 freeLiquidityAvailable);

    address public insurancePool;
    address public claimManager;

    event InsurancePoolUpdated(address indexed previousPool, address indexed newPool);
    event ClaimManagerUpdated(
        address indexed previousClaimManager, address indexed newClaimManager
    );
    event ClaimPayout(address indexed recipient, uint256 amount);

    constructor(
        IERC20 asset_,
        address initialOwner,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) ERC4626(asset_) Ownable(initialOwner) { }

    modifier onlyClaimManager() {
        if (msg.sender != claimManager) revert CallerNotClaimManager();
        _;
    }

    function setInsurancePool(
        address newInsurancePool
    ) external onlyOwner {
        if (newInsurancePool == address(0)) revert InvalidProtocolAddress();
        emit InsurancePoolUpdated(insurancePool, newInsurancePool);
        insurancePool = newInsurancePool;
    }

    function setClaimManager(
        address newClaimManager
    ) external onlyOwner {
        if (newClaimManager == address(0)) revert InvalidProtocolAddress();
        emit ClaimManagerUpdated(claimManager, newClaimManager);
        claimManager = newClaimManager;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function lockedLiquidity() public view returns (uint256) {
        if (insurancePool == address(0)) {
            return 0;
        }

        return IInsurancePoolCoverageSource(insurancePool).activeCoverage();
    }

    function freeLiquidity() public view returns (uint256) {
        uint256 totalAssetBalance = totalAssets();
        uint256 reservedLiquidity = lockedLiquidity();

        if (reservedLiquidity >= totalAssetBalance) {
            return 0;
        }

        return totalAssetBalance - reservedLiquidity;
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
    ) public override whenNotPaused nonReentrant returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function mint(
        uint256 shares,
        address receiver
    ) public override whenNotPaused nonReentrant returns (uint256) {
        return super.mint(shares, receiver);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override whenNotPaused nonReentrant returns (uint256) {
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
    ) public override whenNotPaused nonReentrant returns (uint256) {
        uint256 assets = previewRedeem(shares);
        uint256 freeLiquidityAvailable = freeLiquidity();
        if (assets > freeLiquidityAvailable) {
            revert WithdrawalExceedsFreeLiquidity(assets, freeLiquidityAvailable);
        }
        return super.redeem(shares, receiver, owner);
    }

    function payClaim(
        address recipient,
        uint256 amount
    ) external onlyClaimManager nonReentrant {
        uint256 freeLiquidityAvailable = freeLiquidity();
        if (amount > freeLiquidityAvailable) {
            revert ClaimAmountExceedsFreeLiquidity(amount, freeLiquidityAvailable);
        }

        IERC20(asset()).safeTransfer(recipient, amount);
        emit ClaimPayout(recipient, amount);
    }
}
