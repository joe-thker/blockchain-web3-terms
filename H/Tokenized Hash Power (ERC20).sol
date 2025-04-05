import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HashPowerToken is ERC20 {
    constructor() ERC20("HashPowerToken", "HPT") {
        _mint(msg.sender, 1_000_000 * 1e18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
