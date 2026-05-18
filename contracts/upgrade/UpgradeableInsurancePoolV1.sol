// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    UUPSUpgradeable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract UpgradeableInsurancePoolV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    error InvalidAddress();

    address public collateralAsset;
    uint256 public totalCoveredAmount;
    uint256 public totalPoliciesSold;

    event SyntheticPolicyRecorded(uint256 coveredAmount, uint256 totalPoliciesSold);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        address collateralAsset_
    ) public initializer {
        if (initialOwner == address(0) || collateralAsset_ == address(0)) revert InvalidAddress();

        __Ownable_init(initialOwner);

        collateralAsset = collateralAsset_;
    }

    function recordSyntheticPolicy(
        uint256 coveredAmount
    ) external onlyOwner {
        totalCoveredAmount += coveredAmount;
        totalPoliciesSold += 1;
        emit SyntheticPolicyRecorded(coveredAmount, totalPoliciesSold);
    }

    function version() external pure virtual returns (string memory) {
        return "v1";
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner { }

    uint256[50] private __gap;
}
