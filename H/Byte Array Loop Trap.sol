contract LoopTrap {
    bytes public data;

    function feedGoodData() external {
        data = abi.encodePacked(uint8(0x10), uint8(0x20), uint8(0x30));
    }

    function feedLoopTrap() external {
        data = abi.encodePacked(uint8(0x10), uint8(0x00), uint8(0x10));
    }

    function process() external view returns (uint256 count) {
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == 0x00) {
                break; // Loop traps prematurely
            }
            count++;
        }
    }
}
