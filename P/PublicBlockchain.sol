// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PublicBlockchainRegistry
 * @notice Defines “Public Blockchain” categories along with common
 *         attack vectors and defense mechanisms. Users can register
 *         and query these combinations on-chain for analysis or governance.
 */
contract PublicBlockchainRegistry {
    /// @notice Types of public blockchains
    enum BlockchainType {
        Permissionless,       // fully open, anyone can join (e.g., Bitcoin)
        PermissionedPublic,   // public reads, restricted writes (e.g., Ripple)
        SmartContractPlatform,// supports on‐chain smart contracts (e.g., Ethereum)
        Layer1Protocol,       // base layer consensus chain
        Sidechain,            // interoperable chain anchored to mainnet
        CrossChainProtocol    // designed for cross‐chain messaging
    }

    /// @notice Attack vectors targeting public blockchains
    enum AttackType {
        FiftyOnePercent,      // >51% hashpower or stake majority
        SybilAttack,          // many fake identities to sway consensus
        NetworkSpam,          // flooding the network with transactions
        SmartContractExploit, // bugs in smart contracts on the chain
        DDoS                  // denial‐of‐service on nodes or RPC endpoints
    }

    /// @notice Defense mechanisms for public blockchains
    enum DefenseType {
        Decentralization,     // wide distribution of nodes
        EconomicIncentives,   // align incentives via staking or fees
        Checkpointing,        // periodic hard‐coded or voted checkpoints
        Sharding,             // split network load into shards
        FormalVerification    // mathematically prove protocol correctness
    }

    struct Term {
        BlockchainType chainType;
        AttackType     attack;
        DefenseType    defense;
        uint256        timestamp;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Term) public terms;

    event TermRegistered(
        uint256 indexed  id,
        BlockchainType   chainType,
        AttackType       attack,
        DefenseType      defense,
        uint256          timestamp
    );

    /**
     * @notice Register a new Public Blockchain term.
     * @param chainType The blockchain category.
     * @param attack    The anticipated attack vector.
     * @param defense   The chosen defense mechanism.
     * @return id       The ID of the newly registered term.
     */
    function registerTerm(
        BlockchainType chainType,
        AttackType     attack,
        DefenseType    defense
    ) external returns (uint256 id) {
        id = nextId++;
        terms[id] = Term({
            chainType: chainType,
            attack:    attack,
            defense:   defense,
            timestamp: block.timestamp
        });
        emit TermRegistered(id, chainType, attack, defense, block.timestamp);
    }

    /**
     * @notice Retrieve details of a registered term.
     * @param id The term ID.
     * @return chainType The blockchain category.
     * @return attack    The attack vector.
     * @return defense   The defense mechanism.
     * @return timestamp When the term was registered.
     */
    function getTerm(uint256 id)
        external
        view
        returns (
            BlockchainType chainType,
            AttackType     attack,
            DefenseType    defense,
            uint256        timestamp
        )
    {
        Term storage t = terms[id];
        require(t.timestamp != 0, "Term not found");
        return (t.chainType, t.attack, t.defense, t.timestamp);
    }
}
