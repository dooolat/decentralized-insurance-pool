// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";
import { GovernanceToken } from "../../contracts/token/GovernanceToken.sol";
import { ProtocolGovernor } from "../../contracts/governance/ProtocolGovernor.sol";
import { ProtocolTimelock } from "../../contracts/governance/ProtocolTimelock.sol";

contract GovernedBox is Ownable {
    uint256 public value;

    constructor(address initialOwner) Ownable(initialOwner) { }

    function setValue(uint256 newValue) external onlyOwner {
        value = newValue;
    }
}

contract GovernanceModuleTest is Test {
    address internal admin = makeAddr("admin");

    GovernanceToken internal token;
    ProtocolTimelock internal timelock;
    ProtocolGovernor internal governor;
    GovernedBox internal box;

    function setUp() public {
        token = new GovernanceToken(admin, 1_000_000 ether);

        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](0);
        timelock = new ProtocolTimelock(proposers, executors, admin);
        governor = new ProtocolGovernor(token, timelock, token.totalSupply());
        box = new GovernedBox(admin);

        vm.startPrank(admin);
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        box.transferOwnership(address(timelock));
        token.delegate(admin);
        vm.stopPrank();
        vm.warp(block.timestamp + 1);
    }

    function testGovernorConfigurationMatchesRequirements() public view {
        assertEq(governor.votingDelay(), 1 days);
        assertEq(governor.votingPeriod(), 1 weeks);
        assertEq(governor.proposalThreshold(), token.totalSupply() / 100);
        assertEq(governor.quorum(token.clock() - 1), (token.totalSupply() * 4) / 100);
    }

    function testTimelockConfigurationMatchesRequirements() public view {
        assertEq(timelock.getMinDelay(), 2 days);
        assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), address(governor)));
        assertTrue(timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0)));
    }

    function testProposalQueuesAndExecutesThroughTimelock() public {
        address[] memory targets = new address[](1);
        targets[0] = address(box);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeCall(GovernedBox.setValue, (42));
        string memory description = "set box value";

        vm.prank(admin);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Pending));

        vm.warp(block.timestamp + governor.votingDelay() + 1);
        vm.prank(admin);
        governor.castVote(proposalId, 1);

        vm.warp(block.timestamp + governor.votingPeriod() + 1);
        bytes32 descriptionHash = keccak256(bytes(description));

        assertTrue(governor.proposalNeedsQueuing(proposalId));
        governor.queue(targets, values, calldatas, descriptionHash);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Queued));

        vm.warp(block.timestamp + timelock.getMinDelay() + 1);
        governor.execute(targets, values, calldatas, descriptionHash);

        assertEq(box.value(), 42);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Executed));
    }

    function testGovernorSupportsCoreInterface() public view {
        assertTrue(governor.supportsInterface(type(IGovernor).interfaceId));
    }
}
