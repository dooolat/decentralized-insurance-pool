// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {
    AggregatorV3Interface
} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";

contract ProtocolForkTest is Test {
    address internal constant MAINNET_ETH_USD_FEED =
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address internal constant MAINNET_USDC =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant MAINNET_UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function testForkReadsChainlinkFeed() public {
        if (!_selectForkIfConfigured()) return;

        AggregatorV3Interface feed = AggregatorV3Interface(MAINNET_ETH_USD_FEED);
        (, int256 answer,, uint256 updatedAt,) = feed.latestRoundData();

        assertEq(feed.decimals(), 8);
        assertGt(answer, 0);
        assertGt(updatedAt, 0);
    }

    function testForkReadsUsdcMetadata() public {
        if (!_selectForkIfConfigured()) return;

        IERC20Metadata usdc = IERC20Metadata(MAINNET_USDC);
        assertEq(usdc.decimals(), 6);
        assertEq(usdc.symbol(), "USDC");
    }

    function testForkReadsUniswapRouterCode() public {
        if (!_selectForkIfConfigured()) return;

        assertGt(MAINNET_UNISWAP_V2_ROUTER.code.length, 0);
    }

    function _selectForkIfConfigured() internal returns (bool) {
        string memory rpcUrl = vm.envOr("MAINNET_RPC_URL", string(""));
        if (bytes(rpcUrl).length == 0) {
            return false;
        }

        vm.createSelectFork(rpcUrl);
        return true;
    }
}
