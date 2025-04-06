contract StableOnlyAMM {
    address public tokenA;
    address public tokenB;

    constructor(address _a, address _b) {
        tokenA = _a;
        tokenB = _b;
    }

    modifier onlyStablePair() {
        require(
            keccak256(abi.encodePacked(tokenA)) != keccak256(abi.encodePacked(tokenB)),
            "Must be two different but stable tokens"
        );
        _;
    }
}
