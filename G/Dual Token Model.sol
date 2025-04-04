// Token A: Utility
contract UtilityToken is ERC20 {
    constructor() ERC20("GameToken", "UTIL") {
        _mint(msg.sender, 1_000_000 * 1e18);
    }
}

// Token B: Governance
contract GovToken is ERC20 {
    constructor() ERC20("GovernanceToken", "GTOK") {
        _mint(msg.sender, 100_000 * 1e18);
    }
}
