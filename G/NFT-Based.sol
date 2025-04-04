import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFTGovToken is ERC721Enumerable {
    uint256 public nextId;

    constructor() ERC721("NFTGov", "NGOV") {}

    function mint() external {
        _mint(msg.sender, nextId++);
    }

    function votingPower(address user) external view returns (uint256) {
        return balanceOf(user); // 1 NFT = 1 vote
    }
}
