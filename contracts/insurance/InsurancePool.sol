// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { PolicyNFT } from "../nft/PolicyNFT.sol";
import { RiskRegistry } from "./RiskRegistry.sol";
import { InsuranceVault } from "../vault/InsuranceVault.sol";

contract InsurancePool is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error InvalidAddress();
    error InvalidCoverageAmount();
    error InvalidDuration();
    error InactiveRiskType(uint256 riskTypeId);
    error CoverageExceedsRiskLimit(uint256 requested, uint256 availableForRisk);
    error CoverageExceedsLiquidity(uint256 requested, uint256 availableLiquidity);
    error PremiumWouldBeZero();
    error PolicyNotActive(uint256 policyId);
    error PolicyNotExpired(uint256 policyId);
    error CallerNotClaimManager();

    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public constant MIN_POLICY_DURATION = 1 days;
    uint256 public constant MAX_POLICY_DURATION = 365 days;

    enum PolicyStatus {
        Active,
        Claimed,
        Expired
    }

    struct Policy {
        uint256 policyId;
        address buyer;
        uint256 riskTypeId;
        uint256 premium;
        uint256 coverageAmount;
        uint256 startTime;
        uint256 endTime;
        PolicyStatus status;
    }

    IERC20 public immutable collateralAsset;
    InsuranceVault private immutable _vault;
    PolicyNFT private immutable _policyNFT;
    RiskRegistry private immutable _riskRegistry;

    address public claimManager;
    uint256 public nextPolicyId = 1;
    uint256 public activeCoverage;

    mapping(uint256 policyId => Policy policy) private _policies;
    mapping(uint256 riskTypeId => uint256 coverageAmount) public activeCoverageByRisk;

    event PolicyCreated(
        uint256 indexed policyId,
        address indexed buyer,
        uint256 indexed riskTypeId,
        uint256 premium,
        uint256 coverageAmount,
        uint256 startTime,
        uint256 endTime
    );
    event PolicyExpired(uint256 indexed policyId);
    event PolicyClaimed(uint256 indexed policyId, uint256 coverageAmount);
    event PremiumPaid(uint256 indexed policyId, address indexed payer, uint256 amount);
    event CoverageReserved(
        uint256 indexed policyId, uint256 indexed riskTypeId, uint256 coverageAmount
    );
    event CoverageReleased(
        uint256 indexed policyId, uint256 indexed riskTypeId, uint256 coverageAmount
    );
    event ClaimManagerUpdated(
        address indexed previousClaimManager, address indexed newClaimManager
    );

    constructor(
        IERC20 collateralAsset_,
        InsuranceVault vault_,
        PolicyNFT policyNFT_,
        RiskRegistry riskRegistry_,
        address initialOwner
    ) Ownable(initialOwner) {
        if (
            address(collateralAsset_) == address(0) || address(vault_) == address(0)
                || address(policyNFT_) == address(0) || address(riskRegistry_) == address(0)
        ) {
            revert InvalidAddress();
        }

        collateralAsset = collateralAsset_;
        _vault = vault_;
        _policyNFT = policyNFT_;
        _riskRegistry = riskRegistry_;
    }

    modifier onlyClaimManager() {
        if (msg.sender != claimManager) revert CallerNotClaimManager();
        _;
    }

    function setClaimManager(
        address newClaimManager
    ) external onlyOwner {
        if (newClaimManager == address(0)) revert InvalidAddress();
        emit ClaimManagerUpdated(claimManager, newClaimManager);
        claimManager = newClaimManager;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function buyPolicy(
        uint256 riskTypeId,
        uint256 coverageAmount,
        uint256 duration
    ) external whenNotPaused nonReentrant returns (uint256 policyId) {
        if (coverageAmount == 0) revert InvalidCoverageAmount();
        if (duration < MIN_POLICY_DURATION || duration > MAX_POLICY_DURATION) {
            revert InvalidDuration();
        }

        RiskRegistry.RiskType memory riskType = _riskRegistry.getRiskType(riskTypeId);
        if (!riskType.active) revert InactiveRiskType(riskTypeId);

        uint256 availableForRisk = riskType.maxCoverage > activeCoverageByRisk[riskTypeId]
            ? riskType.maxCoverage - activeCoverageByRisk[riskTypeId]
            : 0;

        if (coverageAmount > availableForRisk) {
            revert CoverageExceedsRiskLimit(coverageAmount, availableForRisk);
        }

        uint256 liquidityAvailable = availableLiquidity();
        if (coverageAmount > liquidityAvailable) {
            revert CoverageExceedsLiquidity(coverageAmount, liquidityAvailable);
        }

        uint256 premium = calculatePremium(riskTypeId, coverageAmount, duration);
        if (premium == 0) revert PremiumWouldBeZero();

        policyId = nextPolicyId++;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        _policies[policyId] = Policy({
            policyId: policyId,
            buyer: msg.sender,
            riskTypeId: riskTypeId,
            premium: premium,
            coverageAmount: coverageAmount,
            startTime: startTime,
            endTime: endTime,
            status: PolicyStatus.Active
        });

        activeCoverage += coverageAmount;
        activeCoverageByRisk[riskTypeId] += coverageAmount;

        collateralAsset.safeTransferFrom(msg.sender, address(_vault), premium);
        _policyNFT.mint(msg.sender, policyId);

        emit PremiumPaid(policyId, msg.sender, premium);
        emit CoverageReserved(policyId, riskTypeId, coverageAmount);
        emit PolicyCreated(
            policyId, msg.sender, riskTypeId, premium, coverageAmount, startTime, endTime
        );
    }

    function expirePolicy(
        uint256 policyId
    ) external whenNotPaused {
        Policy memory policy = _policies[policyId];
        if (policy.status != PolicyStatus.Active) revert PolicyNotActive(policyId);
        if (block.timestamp < policy.endTime) revert PolicyNotExpired(policyId);
        _expirePolicy(policyId, policy);
    }

    function markPolicyClaimed(
        uint256 policyId
    ) external onlyClaimManager whenNotPaused returns (uint256 payoutAmount) {
        Policy memory policy = _policies[policyId];
        if (policy.status != PolicyStatus.Active) revert PolicyNotActive(policyId);

        _policies[policyId].status = PolicyStatus.Claimed;
        activeCoverage -= policy.coverageAmount;
        activeCoverageByRisk[policy.riskTypeId] -= policy.coverageAmount;

        emit CoverageReleased(policyId, policy.riskTypeId, policy.coverageAmount);
        emit PolicyClaimed(policyId, policy.coverageAmount);
        return policy.coverageAmount;
    }

    function getPolicy(
        uint256 policyId
    ) external view returns (Policy memory) {
        return _policies[policyId];
    }

    function getActivePolicies() external view returns (Policy[] memory activePolicies) {
        uint256 totalPolicies = nextPolicyId - 1;
        uint256 activeCount = 0;

        for (uint256 policyId = 1; policyId <= totalPolicies; ++policyId) {
            if (_policies[policyId].status != PolicyStatus.Active) {
                continue;
            }

            ++activeCount;
        }

        activePolicies = new Policy[](activeCount);
        uint256 index = 0;

        for (uint256 policyId = 1; policyId <= totalPolicies; ++policyId) {
            if (_policies[policyId].status != PolicyStatus.Active) {
                continue;
            }

            activePolicies[index] = _policies[policyId];
            ++index;
        }
    }

    function calculatePremium(
        uint256 riskTypeId,
        uint256 coverageAmount,
        uint256 duration
    ) public view returns (uint256) {
        RiskRegistry.RiskType memory riskType = _riskRegistry.getRiskType(riskTypeId);
        uint256 numerator = coverageAmount * uint256(riskType.premiumRateBps) * duration;
        uint256 denominator = BPS_DENOMINATOR * 365 days;
        return Math.mulDiv(numerator, 1, denominator, Math.Rounding.Ceil);
    }

    function availableLiquidity() public view returns (uint256) {
        uint256 totalAssetBalance = _vault.totalAssets();
        if (activeCoverage >= totalAssetBalance) {
            return 0;
        }

        return totalAssetBalance - activeCoverage;
    }

    function vault() external view returns (address) {
        return address(_vault);
    }

    function policyNFT() external view returns (address) {
        return address(_policyNFT);
    }

    function riskRegistry() external view returns (address) {
        return address(_riskRegistry);
    }

    function _expirePolicy(
        uint256 policyId,
        Policy memory policy
    ) internal {
        _policies[policyId].status = PolicyStatus.Expired;
        activeCoverage -= policy.coverageAmount;
        activeCoverageByRisk[policy.riskTypeId] -= policy.coverageAmount;

        emit CoverageReleased(policyId, policy.riskTypeId, policy.coverageAmount);
        emit PolicyExpired(policyId);
    }
}
