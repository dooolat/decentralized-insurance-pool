// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { ChainlinkOracleAdapter } from "../../contracts/oracle/ChainlinkOracleAdapter.sol";
import { FixtureAggregator } from "../helpers/ProtocolSystemFixture.sol";

contract ChainlinkOracleAdapterTest is Test {
    ChainlinkOracleAdapter internal adapter;
    FixtureAggregator internal feed;

    function setUp() public {
        adapter = new ChainlinkOracleAdapter();
        feed = new FixtureAggregator(8, int256(1_000e8));
    }

    function testGetLatestPriceReturnsCurrentAnswer() public view {
        uint256 price = adapter.getLatestPrice(address(feed), 1 days);

        assertEq(price, 1_000e8);
    }

    function testGetLatestPriceWithTimestampReturnsPriceAndUpdatedAt() public view {
        (uint256 price, uint256 updatedAt) =
            adapter.getLatestPriceWithTimestamp(address(feed), 1 days);

        assertEq(price, 1_000e8);
        assertEq(updatedAt, block.timestamp);
    }

    function testZeroFeedAddressReverts() public {
        vm.expectRevert(ChainlinkOracleAdapter.InvalidFeedAddress.selector);
        adapter.getLatestPrice(address(0), 1 days);
    }

    function testZeroStalenessLimitReverts() public {
        vm.expectRevert(ChainlinkOracleAdapter.InvalidStalenessLimit.selector);
        adapter.getLatestPrice(address(feed), 0);
    }

    function testNonPositiveOracleAnswerReverts() public {
        feed.setAnswer(0);

        vm.expectRevert();
        adapter.getLatestPrice(address(feed), 1 days);
    }

    function testStaleOraclePriceReverts() public {
        vm.warp(3 days);
        uint256 staleTimestamp = block.timestamp - 2 days;
        feed.setRoundData(2, int256(995e8), staleTimestamp, staleTimestamp, 2);

        vm.expectRevert(
            abi.encodeWithSelector(
                ChainlinkOracleAdapter.StaleOraclePrice.selector,
                address(feed),
                staleTimestamp,
                block.timestamp,
                1 days
            )
        );
        adapter.getLatestPrice(address(feed), 1 days);
    }

    function testIncompleteRoundRevertsWhenAnsweredInRoundIsBehind() public {
        feed.setRoundData(4, int256(995e8), block.timestamp, block.timestamp, 3);

        vm.expectRevert(
            abi.encodeWithSelector(
                ChainlinkOracleAdapter.IncompleteRound.selector, address(feed), 4, 3
            )
        );
        adapter.getLatestPrice(address(feed), 1 days);
    }

    function testIncompleteRoundRevertsWhenUpdatedAtPrecedesStartedAt() public {
        feed.setRoundData(5, int256(995e8), block.timestamp, block.timestamp - 1, 5);

        vm.expectRevert(
            abi.encodeWithSelector(
                ChainlinkOracleAdapter.IncompleteRound.selector, address(feed), 5, 5
            )
        );
        adapter.getLatestPrice(address(feed), 1 days);
    }
}
