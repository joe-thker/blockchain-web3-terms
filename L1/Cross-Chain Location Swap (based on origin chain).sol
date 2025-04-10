contract CrossChainSwap {
    mapping(uint256 => bool) public supportedChains;
    mapping(address => bool) public allowed;

    function setChain(uint256 chainId, bool status) external {
        supportedChains[chainId] = status;
    }

    function bridgeSwap(address user, uint256 fromChainId) external payable {
        require(supportedChains[fromChainId], "Unsupported chain");
        allowed[user] = true;
    }

    function redeemSwap() external {
        require(allowed[msg.sender], "Not authorized");
        allowed[msg.sender] = false;
        // Execute swap
    }
}
