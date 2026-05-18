import { useEffect, useMemo, useState } from "react";
import {
  useAccount,
  useChainId,
  useConnect,
  useDisconnect,
  useReadContract,
  useReadContracts,
  useSwitchChain,
  useWriteContract,
} from "wagmi";
import { Address } from "viem";
import {
  addresses,
  claimManagerAbi,
  erc20Abi,
  governanceTokenAbi,
  governorAbi,
  hasCoreAddresses,
  insuranceAmmAbi,
  insurancePoolAbi,
  policyNftAbi,
  riskRegistryAbi,
  subgraphUrl,
  TARGET_CHAIN,
  vaultAbi,
} from "./lib/contracts";
import { formatToken, parseTokenInput } from "./lib/format";
import { toReadableError } from "./lib/errors";

type RiskTypeView = {
  id: number;
  name: string;
  premiumRateBps: number;
  maxCoverage: bigint;
  triggerThreshold: bigint;
  stalenessLimit: bigint;
  active: boolean;
};

type ProposalView = {
  proposalId: string;
  description: string;
  state: string;
  forVotes: string;
  againstVotes: string;
  abstainVotes: string;
};

type PolicyView = {
  id: string;
  buyer: string;
  coverageAmount: string;
  premium: string;
  status: string;
};

const collateralDecimals = Number(import.meta.env.VITE_COLLATERAL_TOKEN_DECIMALS ?? 6);
const governanceDecimals = Number(import.meta.env.VITE_GOVERNANCE_TOKEN_DECIMALS ?? 18);

function App() {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const { connectors, connect } = useConnect();
  const { disconnect } = useDisconnect();
  const { switchChainAsync } = useSwitchChain();
  const { writeContractAsync } = useWriteContract();

  const [error, setError] = useState<string>("");
  const [statusMessage, setStatusMessage] = useState<string>("");
  const [depositAmount, setDepositAmount] = useState("100");
  const [withdrawAmount, setWithdrawAmount] = useState("50");
  const [coverageAmount, setCoverageAmount] = useState("1000");
  const [durationDays, setDurationDays] = useState("30");
  const [claimPolicyId, setClaimPolicyId] = useState("1");
  const [swapAmount, setSwapAmount] = useState("100");
  const [swapMinAmountOut, setSwapMinAmountOut] = useState("1");
  const [voteProposalId, setVoteProposalId] = useState("");
  const [voteSupport, setVoteSupport] = useState<0 | 1 | 2>(1);
  const [riskTypes, setRiskTypes] = useState<RiskTypeView[]>([]);
  const [subgraphPolicies, setSubgraphPolicies] = useState<PolicyView[]>([]);
  const [subgraphProposals, setSubgraphProposals] = useState<ProposalView[]>([]);
  const [ownedPolicyIds, setOwnedPolicyIds] = useState<number[]>([]);

  const onActionError = (err: unknown) => {
    setError(toReadableError(err));
    setStatusMessage("");
  };

  const collateralBalance = useReadContract({
    address: addresses.collateralToken,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: { enabled: Boolean(address && addresses.collateralToken) },
  });

  const votingPower = useReadContract({
    address: addresses.governanceToken,
    abi: governanceTokenAbi,
    functionName: "getVotes",
    args: address ? [address] : undefined,
    query: { enabled: Boolean(address && addresses.governanceToken) },
  });

  const delegateAddress = useReadContract({
    address: addresses.governanceToken,
    abi: governanceTokenAbi,
    functionName: "delegates",
    args: address ? [address] : undefined,
    query: { enabled: Boolean(address && addresses.governanceToken) },
  });

  const vaultShares = useReadContract({
    address: addresses.insuranceVault,
    abi: vaultAbi,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: { enabled: Boolean(address && addresses.insuranceVault) },
  });

  const maxWithdraw = useReadContract({
    address: addresses.insuranceVault,
    abi: vaultAbi,
    functionName: "maxWithdraw",
    args: address ? [address] : undefined,
    query: { enabled: Boolean(address && addresses.insuranceVault) },
  });

  const poolPolicies = useReadContract({
    address: addresses.insurancePool,
    abi: insurancePoolAbi,
    functionName: "getActivePolicies",
    query: { enabled: Boolean(addresses.insurancePool) },
  });

  const reserves = useReadContract({
    address: addresses.insuranceAmm,
    abi: insuranceAmmAbi,
    functionName: "getReserves",
    query: { enabled: Boolean(addresses.insuranceAmm) },
  });

  const riskTypeCount = useReadContract({
    address: addresses.riskRegistry,
    abi: riskRegistryAbi,
    functionName: "riskTypeCount",
    query: { enabled: Boolean(addresses.riskRegistry) },
  });

  const nextPolicyId = useReadContract({
    address: addresses.insurancePool,
    abi: insurancePoolAbi,
    functionName: "nextPolicyId",
    query: { enabled: Boolean(addresses.insurancePool && address) },
  });

  const riskCalls = useMemo(() => {
    const count = Number(riskTypeCount.data ?? 0n);
    return Array.from({ length: count }, (_, index) => ({
      address: addresses.riskRegistry,
      abi: riskRegistryAbi,
      functionName: "getRiskType" as const,
      args: [BigInt(index + 1)],
    }));
  }, [riskTypeCount.data]);

  const riskResults = useReadContracts({
    contracts: riskCalls,
    query: { enabled: riskCalls.length > 0 },
  });

  const nftOwnerCalls = useMemo(() => {
    if (!address || !addresses.policyNft || !nextPolicyId.data) return [];
    const count = Number(nextPolicyId.data) - 1;
    return Array.from({ length: Math.max(count, 0) }, (_, index) => ({
      address: addresses.policyNft,
      abi: policyNftAbi,
      functionName: "ownerOf" as const,
      args: [BigInt(index + 1)],
    }));
  }, [address, nextPolicyId.data]);

  const nftOwners = useReadContracts({
    contracts: nftOwnerCalls,
    query: { enabled: nftOwnerCalls.length > 0 },
  });

  useEffect(() => {
    if (!riskResults.data) return;
    const parsed = riskResults.data
      .map((entry, index) => {
        const tuple = entry.result as
          | readonly [string, number, bigint, Address, bigint, bigint, boolean]
          | undefined;
        if (!tuple) return null;
        return {
          id: index + 1,
          name: tuple[0],
          premiumRateBps: tuple[1],
          maxCoverage: tuple[2],
          triggerThreshold: tuple[4],
          stalenessLimit: tuple[5],
          active: tuple[6],
        } satisfies RiskTypeView;
      })
      .filter(Boolean) as RiskTypeView[];
    setRiskTypes(parsed);
  }, [riskResults.data]);

  useEffect(() => {
    if (!address || !nftOwners.data) return;
    const owned = nftOwners.data.flatMap((entry, index) => {
      const owner = entry.result as Address | undefined;
      return owner?.toLowerCase() === address.toLowerCase() ? [index + 1] : [];
    });
    setOwnedPolicyIds(owned);
  }, [address, nftOwners.data]);

  useEffect(() => {
    const currentSubgraphUrl = subgraphUrl;
    if (!currentSubgraphUrl) return;
    const run = async () => {
      try {
        const response = await fetch(currentSubgraphUrl, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            query: `
              query Dashboard {
                policies(first: 10, orderBy: startTime, orderDirection: desc) {
                  id
                  buyer
                  coverageAmount
                  premium
                  status
                }
                governanceProposals(first: 10, orderBy: createdAt, orderDirection: desc) {
                  proposalId
                  description
                  state
                  forVotes
                  againstVotes
                  abstainVotes
                }
              }
            `,
          }),
        });
        const payload = await response.json();
        setSubgraphPolicies(payload.data?.policies ?? []);
        setSubgraphProposals(payload.data?.governanceProposals ?? []);
      } catch {
        setError("Subgraph query failed. Check VITE_SUBGRAPH_URL.");
      }
    };
    void run();
  }, []);

  const requireTargetChain = async () => {
    if (chainId === TARGET_CHAIN.id) return;
    if (!switchChainAsync) {
      throw new Error("wrong network");
    }
    await switchChainAsync({ chainId: TARGET_CHAIN.id });
  };

  const ensureAllowance = async (
    tokenAddress: Address | undefined,
    spender: Address | undefined,
    amount: bigint
  ) => {
    if (!address || !tokenAddress || !spender) return;
    await writeContractAsync({
      address: tokenAddress,
      abi: erc20Abi,
      functionName: "approve",
      args: [spender, amount],
    });
  };

  const handleDeposit = async () => {
    try {
      setError("");
      await requireTargetChain();
      const assets = parseTokenInput(depositAmount, collateralDecimals);
      await ensureAllowance(addresses.collateralToken, addresses.insuranceVault, assets);
      await writeContractAsync({
        address: addresses.insuranceVault!,
        abi: vaultAbi,
        functionName: "deposit",
        args: [assets, address!],
      });
      setStatusMessage("Vault deposit submitted.");
    } catch (err) {
      onActionError(err);
    }
  };

  const handleWithdraw = async () => {
    try {
      setError("");
      await requireTargetChain();
      const assets = parseTokenInput(withdrawAmount, collateralDecimals);
      await writeContractAsync({
        address: addresses.insuranceVault!,
        abi: vaultAbi,
        functionName: "withdraw",
        args: [assets, address!, address!],
      });
      setStatusMessage("Vault withdrawal submitted.");
    } catch (err) {
      onActionError(err);
    }
  };

  const handleBuyPolicy = async () => {
    try {
      setError("");
      await requireTargetChain();
      const coverage = parseTokenInput(coverageAmount, collateralDecimals);
      await ensureAllowance(addresses.collateralToken, addresses.insurancePool, coverage);
      await writeContractAsync({
        address: addresses.insurancePool!,
        abi: insurancePoolAbi,
        functionName: "buyPolicy",
        args: [1n, coverage, BigInt(Number(durationDays) * 24 * 60 * 60)],
      });
      setStatusMessage("Policy purchase submitted.");
    } catch (err) {
      onActionError(err);
    }
  };

  const handleExecuteClaim = async () => {
    try {
      setError("");
      await requireTargetChain();
      await writeContractAsync({
        address: addresses.claimManager!,
        abi: claimManagerAbi,
        functionName: "executeClaim",
        args: [BigInt(claimPolicyId)],
      });
      setStatusMessage("Claim execution submitted.");
    } catch (err) {
      onActionError(err);
    }
  };

  const handleSwap = async () => {
    try {
      setError("");
      await requireTargetChain();
      const amountIn = parseTokenInput(swapAmount, collateralDecimals);
      const minAmountOut = parseTokenInput(swapMinAmountOut, governanceDecimals);
      await ensureAllowance(addresses.collateralToken, addresses.insuranceAmm, amountIn);
      await writeContractAsync({
        address: addresses.insuranceAmm!,
        abi: insuranceAmmAbi,
        functionName: "swapExactInput",
        args: [addresses.collateralToken!, amountIn, minAmountOut, address!],
      });
      setStatusMessage("AMM swap submitted.");
    } catch (err) {
      onActionError(err);
    }
  };

  const handleVote = async () => {
    try {
      setError("");
      await requireTargetChain();
      await writeContractAsync({
        address: addresses.protocolGovernor!,
        abi: governorAbi,
        functionName: "castVote",
        args: [BigInt(voteProposalId), voteSupport],
      });
      setStatusMessage("Governance vote submitted.");
    } catch (err) {
      onActionError(err);
    }
  };

  const configReady = hasCoreAddresses();

  return (
    <div className="app-shell">
      <div className="hero-strip" />
      <header className="hero">
        <div>
          <p className="eyebrow">Option E • Decentralized Insurance Pool</p>
          <h1>Underwrite risk. Buy protection. Govern the protocol.</h1>
          <p className="lede">
            Full-stack dashboard for ERC-4626 underwriting, policy NFTs, Chainlink-triggered
            claims, AMM swaps, and DAO governance on Base Sepolia.
          </p>
        </div>
        <div className="wallet-card">
          <p className="wallet-label">Wallet</p>
          {isConnected ? (
            <>
              <div className="mono">{address}</div>
              <div className={chainId === TARGET_CHAIN.id ? "pill ok" : "pill warn"}>
                {chainId === TARGET_CHAIN.id ? "Base Sepolia" : "Wrong network"}
              </div>
              <button onClick={() => disconnect()}>Disconnect</button>
            </>
          ) : (
            connectors.map((connector) => (
              <button key={connector.uid} onClick={() => connect({ connector })}>
                Connect with {connector.name}
              </button>
            ))
          )}
          {isConnected && chainId !== TARGET_CHAIN.id ? (
            <button
              onClick={() =>
                switchChainAsync?.({ chainId: TARGET_CHAIN.id }).catch((err) => onActionError(err))
              }
            >
              Switch to Base Sepolia
            </button>
          ) : null}
        </div>
      </header>

      {!configReady ? (
        <section className="panel warning-panel">
          <h2>Deployment Config Missing</h2>
          <p>
            Add the `VITE_*` contract address environment variables before attempting live reads or
            writes. The UI stays honest and keeps write actions disabled until real deployment
            values are available.
          </p>
        </section>
      ) : null}

      {error ? <div className="banner error">{error}</div> : null}
      {statusMessage ? <div className="banner success">{statusMessage}</div> : null}

      <section className="stats-grid">
        <article className="panel stat">
          <h3>Collateral Balance</h3>
          <strong>{formatToken(collateralBalance.data as bigint | undefined, collateralDecimals)}</strong>
        </article>
        <article className="panel stat">
          <h3>Voting Power</h3>
          <strong>{formatToken(votingPower.data as bigint | undefined, governanceDecimals)}</strong>
        </article>
        <article className="panel stat">
          <h3>Delegate</h3>
          <strong className="mono">{String(delegateAddress.data ?? "-")}</strong>
        </article>
        <article className="panel stat">
          <h3>Vault Shares</h3>
          <strong>{formatToken(vaultShares.data as bigint | undefined, collateralDecimals)}</strong>
        </article>
      </section>

      <section className="content-grid">
        <article className="panel">
          <h2>Vault Actions</h2>
          <label>
            Deposit collateral
            <input value={depositAmount} onChange={(e) => setDepositAmount(e.target.value)} />
          </label>
          <button disabled={!isConnected || !configReady} onClick={handleDeposit}>
            Deposit
          </button>
          <label>
            Withdraw collateral
            <input value={withdrawAmount} onChange={(e) => setWithdrawAmount(e.target.value)} />
          </label>
          <button disabled={!isConnected || !configReady} onClick={handleWithdraw}>
            Withdraw
          </button>
          <p className="hint">
            Max withdraw: {formatToken(maxWithdraw.data as bigint | undefined, collateralDecimals)}
          </p>
        </article>

        <article className="panel">
          <h2>Policy Actions</h2>
          <label>
            Coverage amount
            <input value={coverageAmount} onChange={(e) => setCoverageAmount(e.target.value)} />
          </label>
          <label>
            Duration (days)
            <input value={durationDays} onChange={(e) => setDurationDays(e.target.value)} />
          </label>
          <button disabled={!isConnected || !configReady} onClick={handleBuyPolicy}>
            Buy Insurance
          </button>
          <label>
            Claim policy ID
            <input value={claimPolicyId} onChange={(e) => setClaimPolicyId(e.target.value)} />
          </label>
          <button disabled={!isConnected || !configReady} onClick={handleExecuteClaim}>
            Execute Claim
          </button>
        </article>

        <article className="panel">
          <h2>AMM Action</h2>
          <label>
            Swap collateral amount
            <input value={swapAmount} onChange={(e) => setSwapAmount(e.target.value)} />
          </label>
          <label>
            Minimum governance out
            <input value={swapMinAmountOut} onChange={(e) => setSwapMinAmountOut(e.target.value)} />
          </label>
          <button disabled={!isConnected || !configReady} onClick={handleSwap}>
            Swap Through AMM
          </button>
          <p className="hint">
            Reserves:{" "}
            {reserves.data
              ? `${formatToken((reserves.data as readonly [bigint, bigint])[0], collateralDecimals)} / ${formatToken((reserves.data as readonly [bigint, bigint])[1], governanceDecimals)}`
              : "-"}
          </p>
        </article>

        <article className="panel">
          <h2>Governance Vote</h2>
          <label>
            Proposal ID
            <input value={voteProposalId} onChange={(e) => setVoteProposalId(e.target.value)} />
          </label>
          <label>
            Support
            <select value={voteSupport} onChange={(e) => setVoteSupport(Number(e.target.value) as 0 | 1 | 2)}>
              <option value={0}>Against</option>
              <option value={1}>For</option>
              <option value={2}>Abstain</option>
            </select>
          </label>
          <button disabled={!isConnected || !configReady} onClick={handleVote}>
            Vote on Proposal
          </button>
        </article>
      </section>

      <section className="content-grid">
        <article className="panel">
          <h2>Risk Types</h2>
          {riskTypes.length === 0 ? <p>No risk types loaded.</p> : null}
          {riskTypes.map((risk) => (
            <div key={risk.id} className="list-row">
              <div>
                <strong>{risk.name}</strong>
                <p>
                  Rate: {risk.premiumRateBps} bps • Trigger: {risk.triggerThreshold.toString()} •
                  Staleness: {risk.stalenessLimit.toString()}s
                </p>
              </div>
              <span className={risk.active ? "pill ok" : "pill warn"}>
                {risk.active ? "Active" : "Inactive"}
              </span>
            </div>
          ))}
        </article>

        <article className="panel">
          <h2>Policy NFTs</h2>
          {ownedPolicyIds.length === 0 ? <p>No PolicyNFTs found for the connected wallet.</p> : null}
          {ownedPolicyIds.map((policyId) => (
            <div key={policyId} className="list-row">
              <strong>Policy #{policyId}</strong>
              <span className="mono">Owner verified onchain</span>
            </div>
          ))}
        </article>

        <article className="panel">
          <h2>Active Policies</h2>
          {subgraphPolicies.length > 0 ? (
            subgraphPolicies.map((policy) => (
              <div key={policy.id} className="list-row">
                <div>
                  <strong>Policy #{policy.id}</strong>
                  <p>
                    Buyer {policy.buyer.slice(0, 6)}... • Coverage {policy.coverageAmount} • Premium{" "}
                    {policy.premium}
                  </p>
                </div>
                <span className="pill ok">{policy.status}</span>
              </div>
            ))
          ) : poolPolicies.data ? (
            (poolPolicies.data as readonly unknown[]).map((policy, index) => (
              <div key={index} className="list-row">
                <strong>Onchain active policy</strong>
                <span className="mono">Loaded directly from the insurance pool contract.</span>
              </div>
            ))
          ) : (
            <p>Set `VITE_SUBGRAPH_URL` to load indexed policy history from The Graph.</p>
          )}
        </article>

        <article className="panel">
          <h2>Governance Proposals</h2>
          {subgraphProposals.length === 0 ? (
            <p>Set `VITE_SUBGRAPH_URL` to load indexed proposal state from The Graph.</p>
          ) : (
            subgraphProposals.map((proposal) => (
              <div key={proposal.proposalId} className="list-row">
                <div>
                  <strong>Proposal #{proposal.proposalId}</strong>
                  <p>{proposal.description || "No description"}</p>
                  <p>
                    For {proposal.forVotes} • Against {proposal.againstVotes} • Abstain{" "}
                    {proposal.abstainVotes}
                  </p>
                </div>
                <span className="pill ok">{proposal.state}</span>
              </div>
            ))
          )}
        </article>
      </section>
    </div>
  );
}

export default App;
