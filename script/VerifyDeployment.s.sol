// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ProtocolGovernor } from "../contracts/governance/ProtocolGovernor.sol";
import { ProtocolTimelock } from "../contracts/governance/ProtocolTimelock.sol";
import { RiskRegistry } from "../contracts/insurance/RiskRegistry.sol";

interface IClockLike {
    function clock() external view returns (uint48);
}

contract VerifyDeployment is Script {
    function run() external view {
        address timelockAddress = vm.envAddress("PROTOCOL_TIMELOCK");
        address governorAddress = vm.envAddress("PROTOCOL_GOVERNOR");
        address policyNft = vm.envAddress("POLICY_NFT");
        address insuranceVault = vm.envAddress("INSURANCE_VAULT");
        address insurancePool = vm.envAddress("INSURANCE_POOL");
        address insuranceFactory = vm.envAddress("INSURANCE_FACTORY");
        address riskRegistry = vm.envAddress("RISK_REGISTRY");
        uint256 initialGovSupply = vm.envUint("INITIAL_GOV_SUPPLY");

        ProtocolTimelock timelock = ProtocolTimelock(payable(timelockAddress));
        ProtocolGovernor governor = ProtocolGovernor(payable(governorAddress));

        require(timelock.getMinDelay() == 2 days, "timelock delay mismatch");
        require(governor.votingDelay() == 1 days, "voting delay mismatch");
        require(governor.votingPeriod() == 1 weeks, "voting period mismatch");
        require(governor.proposalThreshold() == initialGovSupply / 100, "threshold mismatch");
        uint48 currentClock = IClockLike(address(governor.token())).clock();
        require(currentClock > 0, "governance clock not initialized");
        require(
            governor.quorum(uint256(currentClock) - 1) == (initialGovSupply * 4) / 100,
            "quorum mismatch"
        );

        require(Ownable(policyNft).owner() == timelockAddress, "PolicyNFT owner mismatch");
        require(Ownable(insuranceVault).owner() == timelockAddress, "vault owner mismatch");
        require(Ownable(insurancePool).owner() == timelockAddress, "pool owner mismatch");
        require(Ownable(insuranceFactory).owner() == timelockAddress, "factory owner mismatch");

        bytes32 riskManagerRole = RiskRegistry(riskRegistry).RISK_MANAGER_ROLE();
        require(
            AccessControl(riskRegistry).hasRole(riskManagerRole, timelockAddress),
            "timelock missing risk manager role"
        );
        require(
            timelock.hasRole(timelock.PROPOSER_ROLE(), governorAddress),
            "governor missing proposer role"
        );
    }
}
