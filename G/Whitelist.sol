contract GSN_Whitelist {
    address public owner;
    mapping(address => bool) public whitelist;

    constructor() {
        owner = msg.sender;
    }

    function addToWhitelist(address user) external {
        require(msg.sender == owner);
        whitelist[user] = true;
    }

    function isWhitelisted(address user) public view returns (bool) {
        return whitelist[user];
    }

    function gaslessAction() external {
        require(whitelist[msg.sender], "Not whitelisted");
        // Action logic
    }
}
