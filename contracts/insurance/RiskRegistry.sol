// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

contract RiskRegistry is AccessControl {
    error InvalidPremiumRate();
    error InvalidCoverageLimit();
    error InvalidOracleFeed();
    error InvalidStalenessLimit();
    error RiskTypeNotFound(uint256 riskTypeId);

    bytes32 public constant RISK_MANAGER_ROLE = keccak256("RISK_MANAGER_ROLE");

    struct RiskType {
        string name;
        uint16 premiumRateBps;
        uint256 maxCoverage;
        address oracleFeed;
        uint256 triggerThreshold;
        uint256 stalenessLimit;
        bool active;
    }

    uint256 public riskTypeCount;
    mapping(uint256 riskTypeId => RiskType riskType) private _riskTypes;

    event RiskTypeAdded(
        uint256 indexed riskTypeId,
        string name,
        uint16 premiumRateBps,
        uint256 maxCoverage,
        address indexed oracleFeed,
        uint256 triggerThreshold,
        uint256 stalenessLimit
    );
    event RiskTypeUpdated(
        uint256 indexed riskTypeId,
        string name,
        uint16 premiumRateBps,
        uint256 maxCoverage,
        address indexed oracleFeed,
        uint256 triggerThreshold,
        uint256 stalenessLimit,
        bool active
    );
    event RiskTypeDeactivated(uint256 indexed riskTypeId);

    constructor(
        address admin
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(RISK_MANAGER_ROLE, admin);
    }

    function addRiskType(
        string calldata name,
        uint16 premiumRateBps,
        uint256 maxCoverage,
        address oracleFeed,
        uint256 triggerThreshold,
        uint256 stalenessLimit
    ) external onlyRole(RISK_MANAGER_ROLE) returns (uint256 riskTypeId) {
        _validateRiskType(premiumRateBps, maxCoverage, oracleFeed, stalenessLimit);

        riskTypeId = ++riskTypeCount;
        _riskTypes[riskTypeId] = RiskType({
            name: name,
            premiumRateBps: premiumRateBps,
            maxCoverage: maxCoverage,
            oracleFeed: oracleFeed,
            triggerThreshold: triggerThreshold,
            stalenessLimit: stalenessLimit,
            active: true
        });

        emit RiskTypeAdded(
            riskTypeId,
            name,
            premiumRateBps,
            maxCoverage,
            oracleFeed,
            triggerThreshold,
            stalenessLimit
        );
    }

    function updateRiskType(
        uint256 riskTypeId,
        string calldata name,
        uint16 premiumRateBps,
        uint256 maxCoverage,
        address oracleFeed,
        uint256 triggerThreshold,
        uint256 stalenessLimit,
        bool active
    ) external onlyRole(RISK_MANAGER_ROLE) {
        _requireRiskTypeExists(riskTypeId);
        _validateRiskType(premiumRateBps, maxCoverage, oracleFeed, stalenessLimit);

        _riskTypes[riskTypeId] = RiskType({
            name: name,
            premiumRateBps: premiumRateBps,
            maxCoverage: maxCoverage,
            oracleFeed: oracleFeed,
            triggerThreshold: triggerThreshold,
            stalenessLimit: stalenessLimit,
            active: active
        });

        emit RiskTypeUpdated(
            riskTypeId,
            name,
            premiumRateBps,
            maxCoverage,
            oracleFeed,
            triggerThreshold,
            stalenessLimit,
            active
        );
    }

    function deactivateRiskType(
        uint256 riskTypeId
    ) external onlyRole(RISK_MANAGER_ROLE) {
        _requireRiskTypeExists(riskTypeId);
        _riskTypes[riskTypeId].active = false;
        emit RiskTypeDeactivated(riskTypeId);
    }

    function getRiskType(
        uint256 riskTypeId
    ) external view returns (RiskType memory) {
        _requireRiskTypeExists(riskTypeId);
        return _riskTypes[riskTypeId];
    }

    function _validateRiskType(
        uint16 premiumRateBps,
        uint256 maxCoverage,
        address oracleFeed,
        uint256 stalenessLimit
    ) internal pure {
        if (premiumRateBps == 0 || premiumRateBps > 10_000) {
            revert InvalidPremiumRate();
        }
        if (maxCoverage == 0) {
            revert InvalidCoverageLimit();
        }
        if (oracleFeed == address(0)) {
            revert InvalidOracleFeed();
        }
        if (stalenessLimit == 0) {
            revert InvalidStalenessLimit();
        }
    }

    function _requireRiskTypeExists(
        uint256 riskTypeId
    ) internal view {
        if (riskTypeId == 0 || riskTypeId > riskTypeCount) {
            revert RiskTypeNotFound(riskTypeId);
        }
    }
}
