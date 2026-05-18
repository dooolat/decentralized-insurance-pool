// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { GovernanceToken } from "../../contracts/token/GovernanceToken.sol";
import { PolicyNFT } from "../../contracts/nft/PolicyNFT.sol";
import { RiskRegistry } from "../../contracts/insurance/RiskRegistry.sol";
import { InsuranceVault } from "../../contracts/vault/InsuranceVault.sol";
import { InsurancePool } from "../../contracts/insurance/InsurancePool.sol";
import { ClaimManager } from "../../contracts/insurance/ClaimManager.sol";
import { ChainlinkOracleAdapter } from "../../contracts/oracle/ChainlinkOracleAdapter.sol";

contract FixtureCollateralToken is ERC20 {
    constructor() ERC20("Fixture USD", "fUSD") { }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract FixtureAggregator {
    uint8 public immutable decimals;

    uint80 public roundId;
    int256 public answer;
    uint256 public startedAt;
    uint256 public updatedAt;
    uint80 public answeredInRound;

    constructor(uint8 decimals_, int256 answer_) {
        decimals = decimals_;
        setRoundData(1, answer_, block.timestamp, block.timestamp, 1);
    }

    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }

    function setAnswer(int256 newAnswer) external {
        setRoundData(roundId + 1, newAnswer, block.timestamp, block.timestamp, roundId + 1);
    }

    function setUpdatedAt(uint256 newUpdatedAt) external {
        updatedAt = newUpdatedAt;
    }

    function setRoundData(
        uint80 roundId_,
        int256 answer_,
        uint256 startedAt_,
        uint256 updatedAt_,
        uint80 answeredInRound_
    ) public {
        roundId = roundId_;
        answer = answer_;
        startedAt = startedAt_;
        updatedAt = updatedAt_;
        answeredInRound = answeredInRound_;
    }
}

abstract contract ProtocolSystemFixture is Test {
    uint256 internal constant INITIAL_GOVERNANCE_SUPPLY = 1_000_000 ether;
    uint256 internal constant DEFAULT_VAULT_DEPOSIT = 1_000_000e6;
    uint256 internal constant DEFAULT_MAX_COVERAGE = 500_000e6;
    uint256 internal constant DEFAULT_STALENESS = 1 days;
    uint256 internal constant DEFAULT_TRIGGER = 950e8;

    address internal admin = makeAddr("admin");
    address internal underwriter = makeAddr("underwriter");
    address internal buyer = makeAddr("buyer");
    address internal operator = makeAddr("operator");
    address internal stranger = makeAddr("stranger");

    GovernanceToken internal governanceToken;
    FixtureCollateralToken internal collateralToken;
    PolicyNFT internal policyNft;
    RiskRegistry internal riskRegistry;
    InsuranceVault internal vault;
    ChainlinkOracleAdapter internal oracleAdapter;
    InsurancePool internal insurancePool;
    ClaimManager internal claimManager;
    FixtureAggregator internal priceFeed;

    uint256 internal riskTypeId;

    function setUp() public virtual {
        governanceToken = new GovernanceToken(admin, INITIAL_GOVERNANCE_SUPPLY);
        collateralToken = new FixtureCollateralToken();
        policyNft = new PolicyNFT(admin, "ipfs://policy/");
        riskRegistry = new RiskRegistry(admin);
        vault = new InsuranceVault(collateralToken, admin, "Insurance Vault Share", "IVS");
        oracleAdapter = new ChainlinkOracleAdapter();
        priceFeed = new FixtureAggregator(8, int256(1_000e8));

        vm.prank(admin);
        riskTypeId = riskRegistry.addRiskType(
            "STABLECOIN_DEPEG",
            500,
            DEFAULT_MAX_COVERAGE,
            address(priceFeed),
            DEFAULT_TRIGGER,
            DEFAULT_STALENESS
        );

        insurancePool =
            new InsurancePool(collateralToken, vault, policyNft, riskRegistry, admin);
        claimManager = new ClaimManager(
            insurancePool, riskRegistry, vault, policyNft, oracleAdapter, admin
        );

        vm.startPrank(admin);
        policyNft.setInsurancePool(address(insurancePool));
        vault.setInsurancePool(address(insurancePool));
        vault.setClaimManager(address(claimManager));
        insurancePool.setClaimManager(address(claimManager));
        vm.stopPrank();

        collateralToken.mint(underwriter, 2_000_000e6);
        collateralToken.mint(buyer, 2_000_000e6);

        vm.prank(underwriter);
        collateralToken.approve(address(vault), type(uint256).max);
        vm.prank(buyer);
        collateralToken.approve(address(insurancePool), type(uint256).max);

        vm.prank(underwriter);
        vault.deposit(DEFAULT_VAULT_DEPOSIT, underwriter);
    }

    function _buyPolicy(uint256 coverageAmount, uint256 duration)
        internal
        returns (uint256 policyId, InsurancePool.Policy memory policy)
    {
        vm.prank(buyer);
        policyId = insurancePool.buyPolicy(riskTypeId, coverageAmount, duration);
        policy = insurancePool.getPolicy(policyId);
    }

    function _setPrice(int256 newAnswer) internal {
        priceFeed.setAnswer(newAnswer);
    }

    function _setStalePrice(int256 newAnswer, uint256 staleBy) internal {
        uint256 staleTimestamp = block.timestamp - staleBy;
        priceFeed.setRoundData(2, newAnswer, staleTimestamp, staleTimestamp, 2);
    }
}
