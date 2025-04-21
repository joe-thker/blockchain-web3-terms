// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NetworkRegistry
 * @notice Registry of chain IDs → network metadata.
 *
 * FIX: Added `constructor() Ownable(msg.sender)` so the
 *      OpenZeppelin Ownable base constructor receives its
 *      required `initialOwner` argument, eliminating the
 *      “No arguments passed to the base constructor” error.
 */
contract NetworkRegistry is Ownable {
    struct NetworkInfo {
        uint256 chainId;
        string  name;
        string  explorer;
        mapping(string => address) addresses;
        bool exists;
    }

    uint256 public nextId = 1;
    mapping(uint256 => NetworkInfo) private _networks;
    mapping(uint256 => uint256) public idByChain;

    event NetworkAdded(uint256 indexed id, uint256 chainId, string name);
    event AddressSet(uint256 indexed id, string key, address addr);

    /// @notice Passes msg.sender as initial owner to Ownable
    constructor() Ownable(msg.sender) {}

    /// @notice Add a new network
    function addNetwork(
        uint256 chainId,
        string calldata name,
        string calldata explorer
    ) external onlyOwner returns (uint256 id) {
        require(idByChain[chainId] == 0, "chain exists");
        id = nextId++;
        NetworkInfo storage n = _networks[id];
        n.chainId  = chainId;
        n.name     = name;
        n.explorer = explorer;
        n.exists   = true;
        idByChain[chainId] = id;
        emit NetworkAdded(id, chainId, name);
    }

    /// @notice Set a named address (e.g., "WFTM") for a network
    function setAddress(
        uint256 id,
        string calldata key,
        address addr
    ) external onlyOwner {
        require(_networks[id].exists, "bad id");
        _networks[id].addresses[key] = addr;
        emit AddressSet(id, key, addr);
    }

    /// @notice Get basic info (name, explorer URL) for a chain ID
    function getNetwork(uint256 chainId)
        external
        view
        returns (
            string memory name,
            string memory explorer,
            address wftm
        )
    {
        uint256 id = idByChain[chainId];
        require(id != 0, "unknown chain");
        NetworkInfo storage n = _networks[id];
        name     = n.name;
        explorer = n.explorer;
        wftm     = n.addresses["WFTM"];
    }
}
