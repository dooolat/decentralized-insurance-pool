// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract AssemblyBenchmark {
    function sumSolidity(
        uint256[] memory values
    ) external pure returns (uint256 total) {
        uint256 length = values.length;
        for (uint256 index; index < length; ++index) {
            total += values[index];
        }
    }

    function sumAssembly(
        uint256[] memory values
    ) external pure returns (uint256 total) {
        assembly {
            let length := mload(values)
            let cursor := add(values, 0x20)
            let end := add(cursor, mul(length, 0x20))

            for { } lt(cursor, end) { cursor := add(cursor, 0x20) } {
                total := add(total, mload(cursor))
            }
        }
    }
}
