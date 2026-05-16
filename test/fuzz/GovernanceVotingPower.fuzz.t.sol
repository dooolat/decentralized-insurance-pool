// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { BaseProtocolTest } from "../helpers/BaseProtocolTest.sol";

contract GovernanceVotingPowerFuzzTest is BaseProtocolTest {
    function testFuzzDelegatedVotingPowerTracksOwnerBalance(
        uint96 transferAmount
    ) public {
        transferAmount = uint96(bound(uint256(transferAmount), 1, governanceToken.balanceOf(owner)));

        vm.prank(owner);
        governanceToken.delegate(owner);

        vm.prank(owner);
        governanceToken.transfer(stranger, transferAmount);

        assertEq(governanceToken.getVotes(owner), governanceToken.balanceOf(owner));
    }

    function testFuzzRecipientCanSelfDelegateTransferredVotes(
        uint96 transferAmount
    ) public {
        transferAmount = uint96(bound(uint256(transferAmount), 1 ether, 25_000 ether));

        vm.prank(owner);
        governanceToken.transfer(stranger, transferAmount);

        vm.prank(stranger);
        governanceToken.delegate(stranger);

        assertEq(governanceToken.getVotes(stranger), transferAmount);
    }

    function testFuzzVotePowerMovesWithMultipleDelegations(
        uint96 transferAmount
    ) public {
        transferAmount = uint96(bound(uint256(transferAmount), 1 ether, 10_000 ether));

        vm.prank(owner);
        governanceToken.transfer(stranger, transferAmount);

        vm.prank(owner);
        governanceToken.delegate(owner);
        vm.prank(stranger);
        governanceToken.delegate(secondaryTrader);

        assertEq(governanceToken.getVotes(owner), governanceToken.balanceOf(owner));
        assertEq(governanceToken.getVotes(secondaryTrader), transferAmount);
    }
}
