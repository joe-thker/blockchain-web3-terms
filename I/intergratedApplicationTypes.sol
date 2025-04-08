// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// 1. Payment Gateway Integration
contract PaymentGatewayApp is Ownable {
    IERC20 public token;
    event Payment(address indexed user, uint256 amount);

    constructor(IERC20 _token) Ownable(msg.sender) {
        token = _token;
    }

    function pay(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        emit Payment(msg.sender, amount);
    }
}

/// 2. Oracle-Connected Data Feed App
interface IPriceOracle {
    function getLatestPrice() external view returns (int256);
}

contract OracleFeedApp {
    IPriceOracle public oracle;

    constructor(address _oracle) {
        oracle = IPriceOracle(_oracle);
    }

    function getPrice() external view returns (int256) {
        return oracle.getLatestPrice();
    }
}

/// 3. NFT + Metadata Indexing App
interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract NFTMetadataApp {
    event MetadataStored(address indexed user, uint256 tokenId, string ipfsHash);
    function storeMetadata(uint256 tokenId, string memory ipfsHash) public {
        emit MetadataStored(msg.sender, tokenId, ipfsHash);
    }
}

/// 4. Multisig + Off-Chain Record App
contract MultisigRecordApp is Ownable {
    mapping(bytes32 => bool) public approvals;

    event ActionApproved(address indexed signer, string action);

    constructor() Ownable(msg.sender) {}

    function approveAction(string memory actionId) external onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(actionId));
        approvals[key] = true;
        emit ActionApproved(msg.sender, actionId);
    }
}

/// 5. DAO Integration App
contract DAOIntegratedApp {
    address public dao;
    event RequestSubmitted(address indexed user, string purpose);

    constructor(address _dao) {
        dao = _dao;
    }

    function submitRequest(string calldata purpose) external {
        emit RequestSubmitted(msg.sender, purpose);
    }

    function updateDAO(address newDAO) external {
        require(msg.sender == dao, "Only DAO");
        dao = newDAO;
    }
}
