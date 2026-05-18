// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { InsuranceFactory } from "../../contracts/factory/InsuranceFactory.sol";

contract FactoryMockDeployed {
    uint256 public immutable value;

    constructor(uint256 value_) {
        value = value_;
    }
}

contract InsuranceFactoryTest is Test {
    address internal owner = makeAddr("owner");
    address internal stranger = makeAddr("stranger");

    InsuranceFactory internal factory;

    function setUp() public {
        factory = new InsuranceFactory(owner);
    }

    function testDeployCreateRejectsEmptyCreationCode() public {
        vm.prank(owner);
        vm.expectRevert(InsuranceFactory.EmptyCreationCode.selector);
        factory.deployCreate("");
    }

    function testDeployCreateRejectsNonOwner() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger)
        );
        factory.deployCreate(type(FactoryMockDeployed).creationCode);
    }

    function testDeployCreateDeploysContract() public {
        bytes memory creationCode =
            abi.encodePacked(type(FactoryMockDeployed).creationCode, abi.encode(77));

        vm.prank(owner);
        address deployed = factory.deployCreate(creationCode);

        assertEq(FactoryMockDeployed(deployed).value(), 77);
    }

    function testDeployCreate2PredictionMatchesDeployment() public {
        bytes32 salt = keccak256("coverage-boost");
        bytes memory creationCode =
            abi.encodePacked(type(FactoryMockDeployed).creationCode, abi.encode(123));
        bytes32 creationCodeHash = keccak256(creationCode);

        address predicted = factory.predictDeterministicAddress(salt, creationCodeHash);

        vm.prank(owner);
        address deployed = factory.deployCreate2(salt, creationCode);

        assertEq(deployed, predicted);
        assertEq(FactoryMockDeployed(deployed).value(), 123);
    }

    function testDeployCreate2RejectsEmptyCreationCode() public {
        vm.prank(owner);
        vm.expectRevert(InsuranceFactory.EmptyCreationCode.selector);
        factory.deployCreate2(bytes32("salt"), "");
    }
}
