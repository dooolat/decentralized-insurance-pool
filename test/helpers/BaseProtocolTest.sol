// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { GovernanceToken } from "../../contracts/token/GovernanceToken.sol";
import { InsuranceVault } from "../../contracts/vault/InsuranceVault.sol";
import { RiskRegistry } from "../../contracts/insurance/RiskRegistry.sol";
import { IInsurancePool } from "../../contracts/interfaces/IInsurancePool.sol";

contract MockCollateralToken is ERC20 {
    uint8 private immutable _tokenDecimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _tokenDecimals = decimals_;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _tokenDecimals;
    }
}

contract MockPriceFeed {
    uint8 public immutable decimals;
    int256 public answer;
    uint256 public updatedAt;

    constructor(uint8 decimals_, int256 initialAnswer) {
        decimals = decimals_;
        answer = initialAnswer;
        updatedAt = block.timestamp;
    }

    function updateAnswer(int256 newAnswer) external {
        answer = newAnswer;
        updatedAt = block.timestamp;
    }
}

contract MockInsuranceAMM {
    address public immutable token0;
    address public immutable token1;

    uint112 private _reserve0;
    uint112 private _reserve1;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    error InvalidTokenIn();
    error InsufficientOutputAmount();
    error InsufficientLiquidity();

    constructor(address token0_, address token1_) {
        token0 = token0_;
        token1 = token1_;
    }

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1) {
        return (_reserve0, _reserve1);
    }

    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external returns (uint256 liquidityMinted, uint256 amount0, uint256 amount1) {
        amount0 = amount0Desired;
        amount1 = amount1Desired;

        if (totalSupply == 0) {
            liquidityMinted = _sqrt(amount0 * amount1);
        } else {
            liquidityMinted = _min(
                (amount0 * totalSupply) / _reserve0,
                (amount1 * totalSupply) / _reserve1
            );
        }

        require(liquidityMinted > 0, "zero liquidity");

        _reserve0 += uint112(amount0);
        _reserve1 += uint112(amount1);
        totalSupply += liquidityMinted;
        balanceOf[msg.sender] += liquidityMinted;
    }

    function getAmountOut(
        uint256 amountIn,
        uint112 reserveIn,
        uint112 reserveOut
    ) public pure returns (uint256 amountOut) {
        if (amountIn == 0 || reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (uint256(reserveIn) * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function swapExactInput(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        address
    ) external returns (uint256 amountOut) {
        if (tokenIn == token0) {
            amountOut = getAmountOut(amountIn, _reserve0, _reserve1);
            if (amountOut < minAmountOut) revert InsufficientOutputAmount();
            _reserve0 += uint112(amountIn);
            _reserve1 -= uint112(amountOut);
            return amountOut;
        }

        if (tokenIn == token1) {
            amountOut = getAmountOut(amountIn, _reserve1, _reserve0);
            if (amountOut < minAmountOut) revert InsufficientOutputAmount();
            _reserve1 += uint112(amountIn);
            _reserve0 -= uint112(amountOut);
            return amountOut;
        }

        revert InvalidTokenIn();
    }

    function _sqrt(uint256 value) internal pure returns (uint256 result) {
        if (value == 0) return 0;
        result = value;
        uint256 x = (value / 2) + 1;
        while (x < result) {
            result = x;
            x = (value / x + x) / 2;
        }
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract MockInsurancePool is IInsurancePool {
    uint8 internal constant STATUS_ACTIVE = 0;
    uint8 internal constant STATUS_CLAIMED = 1;
    uint8 internal constant STATUS_EXPIRED = 2;

    InsuranceVault public immutable vault;
    RiskRegistry public immutable riskRegistry;
    address public immutable owner;
    address public claimManager;

    uint256 public nextPolicyId = 1;
    uint256 public override activeCoverage;

    mapping(uint256 => Policy) private _policies;
    mapping(uint256 => uint256) private _activeCoverageByRisk;

    error Unauthorized();
    error InactiveRiskType();
    error InsufficientLiquidity();
    error PolicyNotFound();
    error InvalidPolicyStatus();

    constructor(
        InsuranceVault vault_,
        RiskRegistry riskRegistry_,
        address owner_
    ) {
        vault = vault_;
        riskRegistry = riskRegistry_;
        owner = owner_;
    }

    function setClaimManager(address claimManager_) external {
        if (msg.sender != owner) revert Unauthorized();
        claimManager = claimManager_;
    }

    function buyPolicy(
        uint256 riskTypeId,
        uint256 coverageAmount,
        uint256 duration
    ) external override returns (uint256 policyId) {
        RiskRegistry.RiskType memory riskType = riskRegistry.getRiskType(riskTypeId);
        if (!riskType.active) revert InactiveRiskType();
        if (availableLiquidity() < coverageAmount) revert InsufficientLiquidity();
        if (_activeCoverageByRisk[riskTypeId] + coverageAmount > riskType.maxCoverage) {
            revert InsufficientLiquidity();
        }

        policyId = nextPolicyId++;
        _policies[policyId] = Policy({
            policyId: policyId,
            buyer: msg.sender,
            riskTypeId: riskTypeId,
            premium: coverageAmount / 20,
            coverageAmount: coverageAmount,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            status: STATUS_ACTIVE
        });

        activeCoverage += coverageAmount;
        _activeCoverageByRisk[riskTypeId] += coverageAmount;
        vault.setReservedCoverage(activeCoverage);
    }

    function expirePolicy(uint256 policyId) external override {
        Policy storage policy = _policies[policyId];
        if (policy.policyId == 0) revert PolicyNotFound();
        if (policy.status != STATUS_ACTIVE) revert InvalidPolicyStatus();
        if (block.timestamp < policy.endTime) revert InvalidPolicyStatus();

        policy.status = STATUS_EXPIRED;
        _releaseCoverage(policy.riskTypeId, policy.coverageAmount);
    }

    function markPolicyClaimed(uint256 policyId) external {
        if (msg.sender != claimManager) revert Unauthorized();

        Policy storage policy = _policies[policyId];
        if (policy.policyId == 0) revert PolicyNotFound();
        if (policy.status != STATUS_ACTIVE) revert InvalidPolicyStatus();

        policy.status = STATUS_CLAIMED;
        _releaseCoverage(policy.riskTypeId, policy.coverageAmount);
    }

    function getPolicy(uint256 policyId) external view override returns (Policy memory) {
        return _policies[policyId];
    }

    function availableLiquidity() public view override returns (uint256) {
        uint256 totalAssets = vault.totalAssets();
        if (activeCoverage >= totalAssets) {
            return 0;
        }
        return totalAssets - activeCoverage;
    }

    function activeCoverageByRisk(
        uint256 riskTypeId
    ) external view override returns (uint256) {
        return _activeCoverageByRisk[riskTypeId];
    }

    function isPolicyClaimed(uint256 policyId) external view override returns (bool) {
        return _policies[policyId].status == STATUS_CLAIMED;
    }

    function _releaseCoverage(uint256 riskTypeId, uint256 coverageAmount) internal {
        activeCoverage -= coverageAmount;
        _activeCoverageByRisk[riskTypeId] -= coverageAmount;
        vault.setReservedCoverage(activeCoverage);
    }
}

contract MockClaimManager {
    MockInsurancePool public immutable pool;
    RiskRegistry public immutable riskRegistry;
    MockPriceFeed public immutable priceFeed;

    error Unauthorized();
    error ClaimConditionNotMet();

    constructor(
        MockInsurancePool pool_,
        RiskRegistry riskRegistry_,
        MockPriceFeed priceFeed_
    ) {
        pool = pool_;
        riskRegistry = riskRegistry_;
        priceFeed = priceFeed_;
    }

    function executeClaim(
        uint256 policyId
    ) external returns (bool paid, uint256 payoutAmount) {
        IInsurancePool.Policy memory policy = pool.getPolicy(policyId);
        if (policy.buyer != msg.sender) revert Unauthorized();

        RiskRegistry.RiskType memory riskType = riskRegistry.getRiskType(policy.riskTypeId);
        if (uint256(int256(priceFeed.answer())) >= riskType.triggerThreshold) {
            revert ClaimConditionNotMet();
        }

        pool.markPolicyClaimed(policyId);
        return (true, policy.coverageAmount);
    }
}

abstract contract BaseProtocolTest is Test {
    uint256 internal constant INITIAL_SUPPLY = 1_000_000 ether;
    uint256 internal constant DEPOSIT_AMOUNT = 1_000_000 * 1e6;
    uint256 internal constant COVERAGE_AMOUNT = 100_000 * 1e6;
    uint256 internal constant DEFAULT_DURATION = 30 days;
    uint256 internal constant DEFAULT_THRESHOLD = 950e8;

    address internal admin = makeAddr("admin");
    address internal owner = admin;
    address internal underwriter = makeAddr("underwriter");
    address internal policyBuyer = makeAddr("policyBuyer");
    address internal buyer = policyBuyer;
    address internal attacker = makeAddr("attacker");
    address internal stranger = attacker;
    address internal treasury = makeAddr("treasury");
    address internal lpProvider = makeAddr("lpProvider");
    address internal trader = makeAddr("trader");
    address internal secondaryTrader = makeAddr("secondaryTrader");

    GovernanceToken internal governanceToken;
    MockCollateralToken internal collateralToken;
    InsuranceVault internal vault;
    RiskRegistry internal riskRegistry;
    MockPriceFeed internal priceFeed;
    MockInsurancePool internal insurancePool;
    MockClaimManager internal claimManager;
    MockInsuranceAMM internal insuranceAmm;

    uint256 internal riskTypeId;

    function setUp() public virtual {
        governanceToken = new GovernanceToken(admin, INITIAL_SUPPLY);
        collateralToken = new MockCollateralToken("Mock USD", "mUSD", 6);
        vault = new InsuranceVault(collateralToken, admin, "Insurance Vault Share", "IVS");
        riskRegistry = new RiskRegistry(admin);
        priceFeed = new MockPriceFeed(8, int256(1000e8));

        vm.prank(admin);
        riskTypeId = riskRegistry.addRiskType(
            "STABLECOIN_DEPEG",
            500,
            500_000 * 1e6,
            address(priceFeed),
            DEFAULT_THRESHOLD,
            1 days
        );

        insurancePool = new MockInsurancePool(vault, riskRegistry, admin);
        claimManager = new MockClaimManager(insurancePool, riskRegistry, priceFeed);
        insuranceAmm = new MockInsuranceAMM(address(collateralToken), address(governanceToken));

        vm.prank(admin);
        vault.transferOwnership(address(insurancePool));
        vm.prank(admin);
        insurancePool.setClaimManager(address(claimManager));

        _seedBalances();
        _seedApprovals();
        _seedVault();
    }

    function _seedBalances() internal {
        collateralToken.mint(underwriter, 2_000_000 * 1e6);
        collateralToken.mint(buyer, 2_000_000 * 1e6);
        collateralToken.mint(lpProvider, 2_000_000 * 1e6);
        collateralToken.mint(trader, 2_000_000 * 1e6);
        collateralToken.mint(secondaryTrader, 2_000_000 * 1e6);

        vm.prank(admin);
        governanceToken.transfer(lpProvider, 200_000 ether);
        vm.prank(admin);
        governanceToken.transfer(trader, 100_000 ether);
        vm.prank(admin);
        governanceToken.transfer(secondaryTrader, 100_000 ether);
        vm.prank(admin);
        governanceToken.transfer(buyer, 50_000 ether);
    }

    function _seedApprovals() internal {
        vm.prank(underwriter);
        collateralToken.approve(address(vault), type(uint256).max);

        vm.prank(buyer);
        collateralToken.approve(address(insurancePool), type(uint256).max);

        vm.prank(lpProvider);
        collateralToken.approve(address(insuranceAmm), type(uint256).max);
        vm.prank(lpProvider);
        governanceToken.approve(address(insuranceAmm), type(uint256).max);

        vm.prank(trader);
        collateralToken.approve(address(insuranceAmm), type(uint256).max);
        vm.prank(trader);
        governanceToken.approve(address(insuranceAmm), type(uint256).max);

        vm.prank(secondaryTrader);
        collateralToken.approve(address(insuranceAmm), type(uint256).max);
        vm.prank(secondaryTrader);
        governanceToken.approve(address(insuranceAmm), type(uint256).max);
    }

    function _seedVault() internal {
        vm.prank(underwriter);
        vault.deposit(DEPOSIT_AMOUNT, underwriter);
    }

    function _buyDefaultPolicy() internal returns (uint256 policyId, uint256 premium) {
        premium = COVERAGE_AMOUNT / 20;
        vm.prank(buyer);
        policyId = insurancePool.buyPolicy(riskTypeId, COVERAGE_AMOUNT, DEFAULT_DURATION);
    }

    function _addDefaultAmmLiquidity() internal returns (uint256 liquidityMinted) {
        vm.prank(lpProvider);
        (liquidityMinted,,) = insuranceAmm.addLiquidity(200_000 * 1e6, 100_000 ether);
    }
}
