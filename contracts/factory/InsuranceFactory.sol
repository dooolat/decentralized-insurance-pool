// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

contract InsuranceFactory is Ownable {
    error EmptyCreationCode();
    error DeploymentFailed();

    event ContractDeployed(address indexed deployer, address indexed deployed, bytes32 codeHash);
    event DeterministicContractDeployed(
        address indexed deployer,
        address indexed deployed,
        bytes32 indexed salt,
        bytes32 codeHash
    );

    constructor(address initialOwner) Ownable(initialOwner) { }

    function deployCreate(
        bytes memory creationCode
    ) external onlyOwner returns (address deployed) {
        if (creationCode.length == 0) revert EmptyCreationCode();

        assembly {
            deployed := create(0, add(creationCode, 0x20), mload(creationCode))
        }

        if (deployed == address(0)) revert DeploymentFailed();
        emit ContractDeployed(msg.sender, deployed, keccak256(creationCode));
    }

    function deployCreate2(
        bytes32 salt,
        bytes memory creationCode
    ) external onlyOwner returns (address deployed) {
        if (creationCode.length == 0) revert EmptyCreationCode();

        deployed = Create2.deploy(0, salt, creationCode);
        emit DeterministicContractDeployed(
            msg.sender,
            deployed,
            salt,
            keccak256(creationCode)
        );
    }

    function predictDeterministicAddress(
        bytes32 salt,
        bytes32 creationCodeHash
    ) external view returns (address) {
        return Create2.computeAddress(salt, creationCodeHash, address(this));
    }
}
