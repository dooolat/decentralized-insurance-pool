// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { AssemblyBenchmark } from "../../contracts/benchmark/AssemblyBenchmark.sol";

contract AssemblyBenchmarkTest is Test {
    AssemblyBenchmark internal benchmark;

    function setUp() public {
        benchmark = new AssemblyBenchmark();
    }

    function testSumImplementationsMatchOnTypicalInput() public view {
        uint256[] memory values = new uint256[](4);
        values[0] = 4;
        values[1] = 8;
        values[2] = 15;
        values[3] = 16;

        assertEq(benchmark.sumSolidity(values), benchmark.sumAssembly(values));
    }

    function testSumImplementationsHandleEmptyArray() public view {
        uint256[] memory values = new uint256[](0);

        assertEq(benchmark.sumSolidity(values), 0);
        assertEq(benchmark.sumAssembly(values), 0);
    }

    function testSumImplementationsHandleLargeNumbers() public view {
        uint256[] memory values = new uint256[](3);
        values[0] = 1e18;
        values[1] = 2e18;
        values[2] = 3e18;

        assertEq(benchmark.sumSolidity(values), 6e18);
        assertEq(benchmark.sumAssembly(values), 6e18);
    }
}
