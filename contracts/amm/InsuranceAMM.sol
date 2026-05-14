// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract InsuranceAMM is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error InvalidToken();
    error InvalidAmount();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();

    uint256 public constant FEE_BPS = 30;
    uint256 public constant FEE_DENOMINATOR = 10_000;
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint112 private _reserve0;
    uint112 private _reserve1;

    event LiquidityAdded(
        address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidityMinted
    );
    event LiquidityRemoved(
        address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidityBurned
    );

    constructor(
        address token0_,
        address token1_
    ) ERC20("Insurance AMM LP Token", "IAMM-LP") {
        if (token0_ == address(0) || token1_ == address(0) || token0_ == token1_) {
            revert InvalidToken();
        }

        token0 = IERC20(token0_);
        token1 = IERC20(token1_);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256) {
        if (amountIn == 0 || reserveIn == 0 || reserveOut == 0) revert InvalidAmount();

        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE_BPS);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * FEE_DENOMINATOR + amountInWithFee;
        return numerator / denominator;
    }

    function getReserves() public view returns (uint112 reserve0, uint112 reserve1) {
        return (_reserve0, _reserve1);
    }

    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external nonReentrant returns (uint256 liquidityMinted, uint256 amount0, uint256 amount1) {
        if (amount0Desired == 0 || amount1Desired == 0) revert InvalidAmount();

        (uint112 reserve0Before, uint112 reserve1Before) = getReserves();

        if (totalSupply() < MINIMUM_LIQUIDITY) {
            amount0 = amount0Desired;
            amount1 = amount1Desired;
            liquidityMinted = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            if (liquidityMinted < 1) revert InsufficientLiquidityMinted();
            _mint(address(1), MINIMUM_LIQUIDITY);
        } else {
            uint256 optimalAmount1 = Math.mulDiv(amount0Desired, reserve1Before, reserve0Before);
            if (optimalAmount1 <= amount1Desired) {
                amount0 = amount0Desired;
                amount1 = optimalAmount1;
            } else {
                uint256 optimalAmount0 = Math.mulDiv(amount1Desired, reserve0Before, reserve1Before);
                amount0 = optimalAmount0;
                amount1 = amount1Desired;
            }

            liquidityMinted = Math.min(
                Math.mulDiv(amount0, totalSupply(), reserve0Before),
                Math.mulDiv(amount1, totalSupply(), reserve1Before)
            );

            if (liquidityMinted < 1) revert InsufficientLiquidityMinted();
        }

        token0.safeTransferFrom(msg.sender, address(this), amount0);
        token1.safeTransferFrom(msg.sender, address(this), amount1);

        _mint(msg.sender, liquidityMinted);
        _updateReserves();

        emit LiquidityAdded(msg.sender, amount0, amount1, liquidityMinted);
    }

    function removeLiquidity(
        uint256 liquidity
    ) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        if (liquidity == 0) revert InvalidAmount();

        uint256 supply = totalSupply();
        amount0 = Math.mulDiv(liquidity, _reserve0, supply);
        amount1 = Math.mulDiv(liquidity, _reserve1, supply);
        if (amount0 < 1 || amount1 < 1) revert InsufficientLiquidityBurned();

        _burn(msg.sender, liquidity);
        token0.safeTransfer(msg.sender, amount0);
        token1.safeTransfer(msg.sender, amount1);
        _updateReserves();

        emit LiquidityRemoved(msg.sender, amount0, amount1, liquidity);
    }

    function _updateReserves() internal {
        _reserve0 = uint112(token0.balanceOf(address(this)));
        _reserve1 = uint112(token1.balanceOf(address(this)));
    }
}
