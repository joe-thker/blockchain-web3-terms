contract StructTrap {
    struct Vault {
        address owner;
        bytes32 safeWord;
    }

    mapping(uint256 => Vault) public vaults;

    function setVault(uint256 id, address _owner, bytes32 _safeWord) external {
        vaults[id] = Vault(_owner, _safeWord);
    }

    function injectHostage(uint256 id) external {
        // Sets safeWord with extra byte hidden in padding
        bytes memory data = abi.encodePacked(bytes32("secret"), bytes1(0xAB));
        assembly {
            sstore(add(vaults.slot, id), mload(add(data, 32)))
        }
    }

    function readVault(uint256 id) public view returns (Vault memory) {
        return vaults[id];
    }
}
