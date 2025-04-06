contract HostageBytes32 {
    bytes public poisonedBytes;

    function storeSafe(bytes32 input) external {
        poisonedBytes = abi.encodePacked(input);
    }

    function storeHostage(bytes32 input) external {
        // Appending 1 malicious byte (e.g. 0x99)
        poisonedBytes = abi.encodePacked(input, bytes1(0x99));
    }

    function readBytes() external view returns (bytes memory) {
        return poisonedBytes;
    }
}
