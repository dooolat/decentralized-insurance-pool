// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract InsuranceAMM is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error InvalidToken();
    error InvalidAmount();

    uint256 public constant FEE_BPS = 30;
    uint256 public constant FEE_DENOMINATOR = 10_000;
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint112 private _reserve0;
    uint112 private _reserve1;

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

    function _updateReserves() internal {
        _reserve0 = uint112(token0.balanceOf(address(this)));
        _reserve1 = uint112(token1.balanceOf(address(this)));
    }
}
