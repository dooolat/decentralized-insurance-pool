// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    AggregatorV3Interface
} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";

contract ChainlinkOracleAdapter {
    error InvalidFeedAddress();
    error InvalidStalenessLimit();
    error InvalidOraclePrice(address feed, int256 answer);
    error StaleOraclePrice(
        address feed, uint256 updatedAt, uint256 currentTime, uint256 stalenessLimit
    );
    error IncompleteRound(address feed, uint80 roundId, uint80 answeredInRound);

    function getLatestPrice(
        address feed,
        uint256 stalenessLimit
    ) external view returns (uint256) {
        (uint256 price,) = getLatestPriceWithTimestamp(feed, stalenessLimit);
        return price;
    }

    function getLatestPriceWithTimestamp(
        address feed,
        uint256 stalenessLimit
    ) public view returns (uint256 price, uint256 updatedAt) {
        if (feed == address(0)) revert InvalidFeedAddress();
        if (stalenessLimit == 0) revert InvalidStalenessLimit();

        AggregatorV3Interface aggregator = AggregatorV3Interface(feed);
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 latestUpdatedAt,
            uint80 answeredInRound
        ) = aggregator.latestRoundData();

        if (answer <= 0) revert InvalidOraclePrice(feed, answer);
        if (answeredInRound < roundId) revert IncompleteRound(feed, roundId, answeredInRound);
        if (startedAt == 0 || latestUpdatedAt < startedAt) {
            revert IncompleteRound(feed, roundId, answeredInRound);
        }
        if (latestUpdatedAt == 0 || block.timestamp > latestUpdatedAt + stalenessLimit) {
            revert StaleOraclePrice(feed, latestUpdatedAt, block.timestamp, stalenessLimit);
        }

        return (uint256(answer), latestUpdatedAt);
    }
}
