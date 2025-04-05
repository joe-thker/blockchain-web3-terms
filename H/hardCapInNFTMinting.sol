import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract HardCappedNFT is ERC721Enumerable {
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public nextTokenId;

    constructor() ERC721("HardCapNFT", "HCNFT") {}

    function mint() external {
        require(totalSupply() < MAX_SUPPLY, "Hard cap reached");
        _mint(msg.sender, nextTokenId++);
    }
}
