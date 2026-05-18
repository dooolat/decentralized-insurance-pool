import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import { ClaimPaid } from "../generated/ClaimManager/ClaimManager";
import {
    PolicyClaimed,
    PolicyCreated,
    PolicyExpired
} from "../generated/InsurancePool/InsurancePool";
import {
    RiskTypeAdded,
    RiskTypeDeactivated,
    RiskTypeUpdated
} from "../generated/RiskRegistry/RiskRegistry";
import { Deposit } from "../generated/InsuranceVault/InsuranceVault";
import {
    LiquidityAdded,
    Swap as SwapEvent
} from "../generated/InsuranceAMM/InsuranceAMM";
import {
    ProposalCreated,
    ProposalExecuted,
    ProposalQueued,
    VoteCast
} from "../generated/ProtocolGovernor/ProtocolGovernor";
import {
    Claim,
    GovernanceProposal,
    LiquidityPosition,
    Policy,
    RiskType,
    Swap,
    VaultDeposit,
    Vote
} from "../generated/schema";

function zeroAddress(): Bytes {
    return Bytes.fromHexString("0x0000000000000000000000000000000000000000") as Bytes;
}

function loadOrCreatePolicy(policyId: BigInt): Policy {
    let entity = Policy.load(policyId.toString());
    if (entity == null) {
        entity = new Policy(policyId.toString());
        entity.policyId = policyId;
        entity.buyer = zeroAddress();
        entity.riskTypeId = BigInt.zero();
        entity.premium = BigInt.zero();
        entity.coverageAmount = BigInt.zero();
        entity.startTime = BigInt.zero();
        entity.endTime = BigInt.zero();
        entity.status = "UNKNOWN";
        entity.createdAt = BigInt.zero();
        entity.updatedAt = BigInt.zero();
    }
    return entity;
}

function loadOrCreateProposal(proposalId: BigInt): GovernanceProposal {
    let entity = GovernanceProposal.load(proposalId.toString());
    if (entity == null) {
        entity = new GovernanceProposal(proposalId.toString());
        entity.proposalId = proposalId;
        entity.proposer = zeroAddress();
        entity.description = "";
        entity.state = "PENDING";
        entity.voteStart = BigInt.zero();
        entity.voteEnd = BigInt.zero();
        entity.forVotes = BigInt.zero();
        entity.againstVotes = BigInt.zero();
        entity.abstainVotes = BigInt.zero();
        entity.updatedAt = BigInt.zero();
    }
    return entity;
}

export function handlePolicyCreated(event: PolicyCreated): void {
    let policy = loadOrCreatePolicy(event.params.policyId);
    policy.buyer = event.params.buyer;
    policy.riskTypeId = event.params.riskTypeId;
    policy.premium = event.params.premium;
    policy.coverageAmount = event.params.coverageAmount;
    policy.startTime = event.params.startTime;
    policy.endTime = event.params.endTime;
    policy.status = "ACTIVE";
    policy.createdAt = event.block.timestamp;
    policy.updatedAt = event.block.timestamp;
    policy.save();
}

export function handlePolicyExpired(event: PolicyExpired): void {
    let policy = loadOrCreatePolicy(event.params.policyId);
    policy.status = "EXPIRED";
    policy.updatedAt = event.block.timestamp;
    policy.save();
}

export function handlePolicyClaimed(event: PolicyClaimed): void {
    let policy = loadOrCreatePolicy(event.params.policyId);
    policy.status = "CLAIMED";
    policy.updatedAt = event.block.timestamp;
    policy.save();
}

export function handleClaimPaid(event: ClaimPaid): void {
    let claim = new Claim(
        event.transaction.hash.toHexString().concat("-").concat(event.logIndex.toString())
    );
    claim.policy = event.params.policyId.toString();
    claim.recipient = event.params.recipient;
    claim.payoutAmount = event.params.payoutAmount;
    claim.txHash = event.transaction.hash;
    claim.createdAt = event.block.timestamp;
    claim.save();
}

export function handleRiskTypeAdded(event: RiskTypeAdded): void {
    let entity = new RiskType(event.params.riskTypeId.toString());
    entity.name = event.params.name;
    entity.premiumRateBps = event.params.premiumRateBps;
    entity.maxCoverage = event.params.maxCoverage;
    entity.oracleFeed = event.params.oracleFeed;
    entity.triggerThreshold = event.params.triggerThreshold;
    entity.stalenessLimit = event.params.stalenessLimit;
    entity.active = true;
    entity.updatedAt = event.block.timestamp;
    entity.save();
}

export function handleRiskTypeUpdated(event: RiskTypeUpdated): void {
    let entity = RiskType.load(event.params.riskTypeId.toString());
    if (entity == null) {
        entity = new RiskType(event.params.riskTypeId.toString());
    }
    entity.name = event.params.name;
    entity.premiumRateBps = event.params.premiumRateBps;
    entity.maxCoverage = event.params.maxCoverage;
    entity.oracleFeed = event.params.oracleFeed;
    entity.triggerThreshold = event.params.triggerThreshold;
    entity.stalenessLimit = event.params.stalenessLimit;
    entity.active = event.params.active;
    entity.updatedAt = event.block.timestamp;
    entity.save();
}

export function handleRiskTypeDeactivated(event: RiskTypeDeactivated): void {
    let entity = RiskType.load(event.params.riskTypeId.toString());
    if (entity == null) return;
    entity.active = false;
    entity.updatedAt = event.block.timestamp;
    entity.save();
}

export function handleVaultDeposit(event: Deposit): void {
    let deposit = new VaultDeposit(
        event.transaction.hash.toHexString().concat("-").concat(event.logIndex.toString())
    );
    deposit.caller = event.params.sender;
    deposit.owner = event.params.owner;
    deposit.assets = event.params.assets;
    deposit.shares = event.params.shares;
    deposit.txHash = event.transaction.hash;
    deposit.createdAt = event.block.timestamp;
    deposit.save();
}

function loadOrCreatePosition(provider: Bytes): LiquidityPosition {
    let entity = LiquidityPosition.load(provider.toHexString());
    if (entity == null) {
        entity = new LiquidityPosition(provider.toHexString());
        entity.provider = provider;
        entity.totalLiquidityMinted = BigInt.zero();
        entity.netLiquidity = BigInt.zero();
        entity.updatedAt = BigInt.zero();
    }
    return entity;
}

export function handleSwap(event: SwapEvent): void {
    let entity = new Swap(
        event.transaction.hash.toHexString().concat("-").concat(event.logIndex.toString())
    );
    entity.sender = event.params.sender;
    entity.tokenIn = event.params.tokenIn;
    entity.amountIn = event.params.amountIn;
    entity.recipient = event.params.recipient;
    entity.amountOut = event.params.amountOut;
    entity.txHash = event.transaction.hash;
    entity.createdAt = event.block.timestamp;
    entity.save();
}

export function handleLiquidityAdded(event: LiquidityAdded): void {
    let entity = loadOrCreatePosition(event.params.provider);
    entity.totalLiquidityMinted = entity.totalLiquidityMinted.plus(event.params.liquidityMinted);
    entity.netLiquidity = entity.netLiquidity.plus(event.params.liquidityMinted);
    entity.updatedAt = event.block.timestamp;
    entity.save();
}

export function handleProposalCreated(event: ProposalCreated): void {
    let entity = loadOrCreateProposal(event.params.proposalId);
    entity.proposer = event.params.proposer;
    entity.description = event.params.description;
    entity.state = "ACTIVE";
    entity.voteStart = event.params.voteStart;
    entity.voteEnd = event.params.voteEnd;
    entity.updatedAt = event.block.timestamp;
    entity.save();
}

export function handleProposalQueued(event: ProposalQueued): void {
    let entity = loadOrCreateProposal(event.params.proposalId);
    entity.state = "QUEUED";
    entity.updatedAt = event.block.timestamp;
    entity.save();
}

export function handleProposalExecuted(event: ProposalExecuted): void {
    let entity = loadOrCreateProposal(event.params.proposalId);
    entity.state = "EXECUTED";
    entity.updatedAt = event.block.timestamp;
    entity.save();
}

export function handleVoteCast(event: VoteCast): void {
    let proposal = loadOrCreateProposal(event.params.proposalId);
    if (event.params.support == 0) {
        proposal.againstVotes = proposal.againstVotes.plus(event.params.weight);
    } else if (event.params.support == 1) {
        proposal.forVotes = proposal.forVotes.plus(event.params.weight);
    } else {
        proposal.abstainVotes = proposal.abstainVotes.plus(event.params.weight);
    }
    proposal.updatedAt = event.block.timestamp;
    proposal.save();

    let vote = new Vote(
        event.transaction.hash.toHexString().concat("-").concat(event.logIndex.toString())
    );
    vote.proposal = proposal.id;
    vote.voter = event.params.voter;
    vote.support = event.params.support;
    vote.weight = event.params.weight;
    vote.reason = event.params.reason;
    vote.createdAt = event.block.timestamp;
    vote.save();
}
