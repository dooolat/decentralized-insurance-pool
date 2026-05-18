// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { PolicyNFT } from "../../contracts/nft/PolicyNFT.sol";

contract PolicyNFTTest is Test {
    address internal owner = makeAddr("owner");
    address internal insurancePool = makeAddr("insurancePool");
    address internal buyer = makeAddr("buyer");
    address internal stranger = makeAddr("stranger");

    PolicyNFT internal policyNft;

    function setUp() public {
        policyNft = new PolicyNFT(owner, "ipfs://policy/");
    }

    function testOwnerCanConfigureInsurancePool() public {
        vm.prank(owner);
        policyNft.setInsurancePool(insurancePool);

        assertEq(policyNft.insurancePool(), insurancePool);
    }

    function testSetInsurancePoolRejectsZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(PolicyNFT.InvalidInsurancePool.selector);
        policyNft.setInsurancePool(address(0));
    }

    function testNonOwnerCannotConfigureInsurancePool() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger)
        );
        policyNft.setInsurancePool(insurancePool);
    }

    function testMintRequiresConfiguredInsurancePool() public {
        vm.prank(insurancePool);
        vm.expectRevert(PolicyNFT.InsurancePoolNotConfigured.selector);
        policyNft.mint(buyer, 1);
    }

    function testOnlyConfiguredInsurancePoolCanMint() public {
        vm.prank(owner);
        policyNft.setInsurancePool(insurancePool);

        vm.prank(stranger);
        vm.expectRevert(PolicyNFT.CallerNotInsurancePool.selector);
        policyNft.mint(buyer, 1);
    }

    function testInsurancePoolCanMintPolicyNft() public {
        vm.prank(owner);
        policyNft.setInsurancePool(insurancePool);

        vm.prank(insurancePool);
        policyNft.mint(buyer, 7);

        assertEq(policyNft.ownerOf(7), buyer);
    }

    function testDuplicatePolicyMintReverts() public {
        vm.prank(owner);
        policyNft.setInsurancePool(insurancePool);

        vm.prank(insurancePool);
        policyNft.mint(buyer, 7);

        vm.prank(insurancePool);
        vm.expectRevert(abi.encodeWithSelector(PolicyNFT.PolicyAlreadyMinted.selector, 7));
        policyNft.mint(buyer, 7);
    }

    function testTokenUriUsesConfiguredBaseUri() public {
        vm.prank(owner);
        policyNft.setInsurancePool(insurancePool);

        vm.prank(insurancePool);
        policyNft.mint(buyer, 15);

        assertEq(policyNft.tokenURI(15), "ipfs://policy/15.json");
    }

    function testTokenUriFallsBackToPolicySchemeWhenBaseUriEmpty() public {
        vm.prank(owner);
        policyNft.setBaseTokenUri("");

        vm.prank(owner);
        policyNft.setInsurancePool(insurancePool);

        vm.prank(insurancePool);
        policyNft.mint(buyer, 3);

        assertEq(policyNft.tokenURI(3), "policy:3");
    }
}
