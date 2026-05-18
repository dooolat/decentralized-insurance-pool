// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { GovernanceToken } from "../../contracts/token/GovernanceToken.sol";

contract GovernanceTokenTest is Test {
    address internal owner = makeAddr("owner");
    address internal voter = makeAddr("voter");
    address internal recipient = makeAddr("recipient");

    uint256 internal constant INITIAL_SUPPLY = 1_000_000 ether;

    GovernanceToken internal token;

    function setUp() public {
        token = new GovernanceToken(owner, INITIAL_SUPPLY);
    }

    function testInitialSupplyMintedToOwner() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }

    function testConstructorRevertsOnZeroInitialSupply() public {
        vm.expectRevert(GovernanceToken.ZeroInitialSupply.selector);
        new GovernanceToken(owner, 0);
    }

    function testDelegationToSelfCreatesVotingPower() public {
        vm.prank(owner);
        token.delegate(owner);

        assertEq(token.delegates(owner), owner);
        assertEq(token.getVotes(owner), INITIAL_SUPPLY);
    }

    function testDelegationToAnotherAddressAssignsVotes() public {
        vm.prank(owner);
        token.delegate(voter);

        assertEq(token.delegates(owner), voter);
        assertEq(token.getVotes(voter), INITIAL_SUPPLY);
    }

    function testTransferUpdatesDelegatedVotingPower() public {
        vm.startPrank(owner);
        token.delegate(owner);
        token.transfer(recipient, 125 ether);
        vm.stopPrank();

        assertEq(token.getVotes(owner), INITIAL_SUPPLY - 125 ether);
        assertEq(token.balanceOf(recipient), 125 ether);
    }

    function testClockUsesTimestampMode() public view {
        assertEq(token.clock(), uint48(block.timestamp));
        assertEq(token.CLOCK_MODE(), "mode=timestamp");
    }

    function testNoncesStartAtZero() public view {
        assertEq(token.nonces(owner), 0);
    }
}
