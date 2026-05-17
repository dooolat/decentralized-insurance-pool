// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IInsurancePool {
    struct Policy {
        uint256 policyId;
        address buyer;
        uint256 riskTypeId;
        uint256 premium;
        uint256 coverageAmount;
        uint256 startTime;
        uint256 endTime;
        uint8 status;
    }

    function activeCoverage() external view returns (uint256);
    function availableLiquidity() external view returns (uint256);
    function activeCoverageByRisk(uint256 riskTypeId) external view returns (uint256);
    function getPolicy(uint256 policyId) external view returns (Policy memory);
    function buyPolicy(
        uint256 riskTypeId,
        uint256 coverageAmount,
        uint256 duration
    ) external returns (uint256 policyId);
    function expirePolicy(uint256 policyId) external;
    function isPolicyClaimed(uint256 policyId) external view returns (bool);
}
