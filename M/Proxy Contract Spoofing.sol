contract ProxyVictim {
    address public implementation;

    function setImplementation(address newImpl) external {
        implementation = newImpl;
    }

    fallback() external payable {
        (bool success, ) = implementation.delegatecall(msg.data);
        require(success, "delegatecall failed");
    }
}
