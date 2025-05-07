// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SpearPhishingSuite
/// @notice Demonstrates insecure vs. secure patterns against spear-phishing attacks
abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

/// Simple reentrancy guard
abstract contract ReentrancyGuard {
    bool private _locked;
    modifier nonReentrant() {
        require(!_locked, "Reentrant");
        _locked = true;
        _;
        _locked = false;
    }
}

//////////////////////////////////////////////////////
// 1) Off-Chain Signature Phishing (Permit)
//////////////////////////////////////////////////////
interface IERC20Permit {
    function permit(
        address owner, address spender, uint256 value,
        uint256 deadline, uint8 v, bytes32 r, bytes32 s
    ) external;
}

contract PhishPermit is Base {
    mapping(address => uint256) public nonces;
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 
        0x8fcbaf0c2ff10628f7e1f8b4e7c1aebf9a5c1e9465a3f80c3c6e5e72b3d2a67d;

    constructor(string memory name) {
        uint256 chainId;
        assembly { chainId := chainid() }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    // --- Attack: naive permit, no domain or nonce
    function permitInsecure(
        address owner_, address spender, uint256 value,
        uint256 deadline, uint8 v, bytes32 r, bytes32 s
    ) external {
        require(block.timestamp <= deadline, "Expired");
        // naive: packing without domain or nonce
        bytes32 hash = keccak256(abi.encodePacked(owner_, spender, value, deadline));
        address signer = ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
            v, r, s
        );
        require(signer == owner_, "Bad sig");
        // allowance logic omitted
    }

    // --- Defense: EIP-712 domain + nonce + expiry
    function permitSecure(
        address owner_, address spender, uint256 value,
        uint256 deadline, uint8 v, bytes32 r, bytes32 s
    ) external {
        require(block.timestamp <= deadline, "Expired");
        uint256 nonce = nonces[owner_]++;
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner_, spender, value, nonce, deadline
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
        address signer = ecrecover(digest, v, r, s);
        require(signer == owner_, "Invalid permit");
        // allowance logic omitted
    }
}

//////////////////////////////////////////////////////
// 2) Phishing via tx.origin
//////////////////////////////////////////////////////
contract PhishOrigin is Base {
    // --- Attack: uses tx.origin
    function withdrawInsecure(uint256 amount) external {
        require(tx.origin == owner, "Not owner");
        payable(owner).transfer(amount);
    }

    // --- Defense: use msg.sender only
    function withdrawSecure(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }

    receive() external payable {}
}

//////////////////////////////////////////////////////
// 3) Unchecked Callback Phishing
//////////////////////////////////////////////////////
interface ICallback {
    function onCall(bytes calldata data) external;
}

contract PhishCallback is Base, ReentrancyGuard {
    mapping(address => bool) public allowedCallbacks;

    event Executed(address callback, bytes data);

    // --- Attack: invokes arbitrary callback
    function execInsecure(address callback, bytes calldata data) external onlyOwner {
        // attacker—controlled callback can reenter or steal funds
        ICallback(callback).onCall(data);
        emit Executed(callback, data);
    }

    // --- Defense: whitelist + ERC-165 interface check + reentrancy guard
    function setCallbackAllowed(address callback, bool ok) external onlyOwner {
        allowedCallbacks[callback] = ok;
    }

    function execSecure(address callback, bytes calldata data) external onlyOwner nonReentrant {
        require(allowedCallbacks[callback], "Callback not allowed");
        // verify implements ICallback
        bytes4 IID = type(ICallback).interfaceId;
        (bool success, bytes memory ret) = callback.staticcall(
            abi.encodeWithSelector(0x01ffc9a7, IID) // ERC165 supportsInterface
        );
        require(success && abi.decode(ret, (bool)), "Not ICallback");
        ICallback(callback).onCall(data);
        emit Executed(callback, data);
    }

    receive() external payable {}
}
