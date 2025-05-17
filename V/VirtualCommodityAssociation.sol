// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VCARegistry - Virtual Commodity Association Registry Smart Contract
contract VCARegistry {
    address public immutable multisig;
    uint256 public constant COMPLIANT = 1;
    uint256 public constant BLACKLISTED = 2;

    struct Commodity {
        uint256 status; // 0 = Unlisted, 1 = Compliant, 2 = Blacklisted
        string description;
        uint256 listedAt;
        uint256 updatedAt;
    }

    mapping(address => Commodity) public commodities;
    mapping(bytes32 => bool) public usedApprovals;

    event CommodityListed(address indexed token, string desc, uint256 status);
    event CommodityUpdated(address indexed token, uint256 newStatus);

    modifier onlyMultisig() {
        require(msg.sender == multisig, "Not multisig");
        _;
    }

    constructor(address _multisig) {
        multisig = _multisig;
    }

    /// @notice Approves a token as a compliant virtual commodity
    function listCommodity(address token, string calldata desc, uint256 status) external onlyMultisig {
        require(status == COMPLIANT || status == BLACKLISTED, "Invalid status");
        commodities[token] = Commodity({
            status: status,
            description: desc,
            listedAt: block.timestamp,
            updatedAt: block.timestamp
        });
        emit CommodityListed(token, desc, status);
    }

    function updateCommodityStatus(address token, uint256 newStatus) external onlyMultisig {
        require(commodities[token].listedAt > 0, "Not listed");
        commodities[token].status = newStatus;
        commodities[token].updatedAt = block.timestamp;
        emit CommodityUpdated(token, newStatus);
    }

    function isCompliant(address token) external view returns (bool) {
        return commodities[token].status == COMPLIANT;
    }

    function isBlacklisted(address token) external view returns (bool) {
        return commodities[token].status == BLACKLISTED;
    }

    /// @notice Verifies signed approval from offchain VCA committee
    function verifyOffchainApproval(
        address token,
        string calldata desc,
        uint256 status,
        uint256 nonce,
        bytes calldata signature
    ) external {
        bytes32 digest = keccak256(abi.encodePacked(token, desc, status, nonce, address(this)));
        require(!usedApprovals[digest], "Already used");

        address signer = recover(digest, signature);
        require(signer == multisig, "Invalid approval signer");

        usedApprovals[digest] = true;

        commodities[token] = Commodity({
            status: status,
            description: desc,
            listedAt: block.timestamp,
            updatedAt: block.timestamp
        });

        emit CommodityListed(token, desc, status);
    }

    function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "Bad signature");
        bytes32 r; bytes32 s; uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return ecrecover(hash, v, r, s);
    }
}
