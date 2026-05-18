// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { UpgradeableInsurancePoolV1 } from "./UpgradeableInsurancePoolV1.sol";

contract UpgradeableInsurancePoolV2 is UpgradeableInsurancePoolV1 {
    uint256 public maxPolicyDuration;

    event MaxPolicyDurationUpdated(uint256 maxPolicyDuration);

    function initializeV2(
        uint256 maxPolicyDuration_
    ) external reinitializer(2) onlyOwner {
        maxPolicyDuration = maxPolicyDuration_;
        emit MaxPolicyDurationUpdated(maxPolicyDuration_);
    }

    function setMaxPolicyDuration(
        uint256 newMaxPolicyDuration
    ) external onlyOwner {
        maxPolicyDuration = newMaxPolicyDuration;
        emit MaxPolicyDurationUpdated(newMaxPolicyDuration);
    }

    function version() external pure override returns (string memory) {
        return "v2";
    }
}
