contract ForkRegistry {
    address public version1;
    address public version2;

    bool public useV2;

    constructor(address _v1, address _v2) {
        version1 = _v1;
        version2 = _v2;
    }

    function toggleFork(bool _useV2) external {
        useV2 = _useV2;
    }

    function getActiveContract() external view returns (address) {
        return useV2 ? version2 : version1;
    }
}
