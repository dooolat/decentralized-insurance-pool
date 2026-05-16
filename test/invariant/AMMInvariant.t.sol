// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { StdInvariant } from "forge-std/StdInvariant.sol";
import { BaseProtocolTest } from "../helpers/BaseProtocolTest.sol";

contract AmmInvariantHandler is BaseProtocolTest {
    function setUp() public override {
        super.setUp();
        _addDefaultAmmLiquidity();
    }

    function swapCollateral(
        uint96 amountIn
    ) external {
        amountIn = uint96(bound(uint256(amountIn), 1e6, 10_000 * 1e6));
        vm.prank(trader);
        try insuranceAmm.swapExactInput(address(collateralToken), amountIn, 1, trader) { } catch { }
    }

    function swapGovernance(
        uint96 amountIn
    ) external {
        amountIn = uint96(bound(uint256(amountIn), 1 ether, 5_000 ether));
        vm.prank(trader);
        try insuranceAmm.swapExactInput(address(governanceToken), amountIn, 1, trader) { } catch { }
    }

    function currentK() external view returns (uint256) {
        (uint112 reserve0, uint112 reserve1) = insuranceAmm.getReserves();
        return uint256(reserve0) * uint256(reserve1);
    }
}

contract AMMInvariantTest is StdInvariant, BaseProtocolTest {
    AmmInvariantHandler internal handler;
    uint256 internal initialK;

    function setUp() public override {
        handler = new AmmInvariantHandler();
        handler.setUp();
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = handler.swapCollateral.selector;
        selectors[1] = handler.swapGovernance.selector;
        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));

        initialK = handler.currentK();
    }

    function invariantKNeverDecreasesAfterSwap() public view {
        assertGe(handler.currentK(), initialK);
    }
}
