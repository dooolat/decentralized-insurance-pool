// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ChainlinkOracleAdapter } from "../oracle/ChainlinkOracleAdapter.sol";
import { InsurancePool } from "./InsurancePool.sol";
import { RiskRegistry } from "./RiskRegistry.sol";
import { InsuranceVault } from "../vault/InsuranceVault.sol";

contract ClaimManager is Ownable, ReentrancyGuard {
    error NotPolicyOwnerOrApproved(uint256 policyId, address caller);
    error PolicyNotActive(uint256 policyId);
    error PolicyAlreadyEnded(uint256 policyId);

    InsurancePool public immutable insurancePool;
    RiskRegistry public immutable riskRegistry;
    InsuranceVault public immutable insuranceVault;
    IERC721 public immutable policyNft;
    ChainlinkOracleAdapter public immutable oracleAdapter;

    event ClaimChecked(
        uint256 indexed policyId,
        address indexed caller,
        uint256 latestPrice,
        uint256 triggerThreshold,
        bool approved
    );
    event ClaimApproved(uint256 indexed policyId, uint256 payoutAmount);
    event ClaimPaid(uint256 indexed policyId, address indexed recipient, uint256 payoutAmount);
    event ClaimRejected(
        uint256 indexed policyId,
        address indexed caller,
        uint256 latestPrice,
        uint256 triggerThreshold
    );

    constructor(
        InsurancePool insurancePool_,
        RiskRegistry riskRegistry_,
        InsuranceVault insuranceVault_,
        IERC721 policyNft_,
        ChainlinkOracleAdapter oracleAdapter_,
        address initialOwner
    ) Ownable(initialOwner) {
        insurancePool = insurancePool_;
        riskRegistry = riskRegistry_;
        insuranceVault = insuranceVault_;
        policyNft = policyNft_;
        oracleAdapter = oracleAdapter_;
    }

    function executeClaim(
        uint256 policyId
    ) external nonReentrant returns (bool paid, uint256 payoutAmount) {
        InsurancePool.Policy memory policy = insurancePool.getPolicy(policyId);
        if (policy.status != InsurancePool.PolicyStatus.Active) revert PolicyNotActive(policyId);
        if (block.timestamp > policy.endTime) revert PolicyAlreadyEnded(policyId);

        _checkPolicyControl(policyId, msg.sender);

        RiskRegistry.RiskType memory riskType = riskRegistry.getRiskType(policy.riskTypeId);
        uint256 latestPrice =
            oracleAdapter.getLatestPrice(riskType.oracleFeed, riskType.stalenessLimit);

        bool approved = latestPrice <= riskType.triggerThreshold;
        emit ClaimChecked(policyId, msg.sender, latestPrice, riskType.triggerThreshold, approved);

        if (!approved) {
            emit ClaimRejected(policyId, msg.sender, latestPrice, riskType.triggerThreshold);
            return (false, 0);
        }

        payoutAmount = insurancePool.markPolicyClaimed(policyId);
        emit ClaimApproved(policyId, payoutAmount);

        insuranceVault.payClaim(policy.buyer, payoutAmount);
        emit ClaimPaid(policyId, policy.buyer, payoutAmount);
        return (true, payoutAmount);
    }

    function isClaimEligible(
        uint256 policyId
    )
        external
        view
        returns (bool eligible, uint256 latestPrice, uint256 triggerThreshold, uint256 updatedAt)
    {
        InsurancePool.Policy memory policy = insurancePool.getPolicy(policyId);
        if (
            policy.status != InsurancePool.PolicyStatus.Active || block.timestamp > policy.endTime
        ) {
            return (false, 0, 0, 0);
        }

        RiskRegistry.RiskType memory riskType = riskRegistry.getRiskType(policy.riskTypeId);
        (latestPrice, updatedAt) =
            oracleAdapter.getLatestPriceWithTimestamp(riskType.oracleFeed, riskType.stalenessLimit);

        triggerThreshold = riskType.triggerThreshold;
        eligible = latestPrice <= triggerThreshold;
    }

    function _checkPolicyControl(
        uint256 policyId,
        address caller
    ) internal view {
        address owner = policyNft.ownerOf(policyId);
        bool approved = owner == caller || policyNft.getApproved(policyId) == caller
            || policyNft.isApprovedForAll(owner, caller);

        if (!approved) {
            revert NotPolicyOwnerOrApproved(policyId, caller);
        }
    }
}
