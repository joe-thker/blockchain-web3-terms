// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    bool private _lock;
    modifier nonReentrant() {
        require(!_lock, "Reentrant");
        _lock = true;
        _;
        _lock = false;
    }
}

//////////////////////////////////////////////////////
// 1) Ownership Transfer Protection
//////////////////////////////////////////////////////
contract SecureOwnable is Base {
    address public pendingOwner;

    // --- Attack: immediate transfer without confirmation
    function transferOwnershipInsecure(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    // --- Defense: two-step handover
    function proposeOwner(address newOwner) external onlyOwner {
        pendingOwner = newOwner;
    }
    function acceptOwnership() external {
        require(msg.sender == pendingOwner, "Not proposed");
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

//////////////////////////////////////////////////////
// 2) Permit (EIP-2612) Approvals
//////////////////////////////////////////////////////
interface IERC20Permit {
    function permit(
        address owner, address spender, uint256 value,
        uint256 deadline, uint8 v, bytes32 r, bytes32 s
    ) external;
}

contract PermitToken is ReentrancyGuard {
    string public name = "PermitToken";
    string public symbol = "DPT";
    uint8  public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Insecure: naive permit payload, no domain or nonce
    function permitInsecure(
        address owner_, address spender, uint256 value,
        uint256 deadline, uint8 v, bytes32 r, bytes32 s
    ) external {
        // naive: no domain separator, no nonce
        bytes32 msgHash = keccak256(abi.encodePacked(owner_, spender, value, deadline));
        address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)), v, r, s);
        require(signer == owner_, "Bad sig");
        require(block.timestamp <= deadline, "Expired");
        allowance[owner_][spender] = value;
    }

    // Secure: EIP-712 domain + nonces + expiry
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x8fcbaf0c2...; 
    mapping(address => uint256) public nonces;

    constructor() {
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

    function permitSecure(
        address owner_, address spender, uint256 value,
        uint256 deadline, uint8 v, bytes32 r, bytes32 s
    ) external nonReentrant {
        require(block.timestamp <= deadline, "Expired");
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner_, spender, value,
                nonces[owner_]++, deadline
            )
        );
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        address signer = ecrecover(hash, v, r, s);
        require(signer == owner_, "Invalid permit");
        allowance[owner_][spender] = value;
    }

    // ERC-20 transfers omitted for brevity...
}

//////////////////////////////////////////////////////
// 3) Timelock Controller
//////////////////////////////////////////////////////
contract Timelock is Base {
    uint256 public minDelay;
    mapping(bytes32 => bool) public queued;

    event Queued(bytes32 id, address target, uint256 value, bytes data, uint256 eta);
    event Executed(bytes32 id, address target, uint256 value, bytes data);

    constructor(uint256 delay_) {
        minDelay = delay_;
    }

    // --- Attack: insecure queue+execute without delay
    function executeInsecure(address target, uint256 value, bytes calldata data) external onlyOwner {
        (bool ok,) = target.call{ value: value }(data);
        require(ok, "Exec failed");
    }

    // --- Defense: queue with ETA, enforce at least minDelay
    function queue(
        address target, uint256 value, bytes calldata data, uint256 eta
    ) external onlyOwner {
        require(eta >= block.timestamp + minDelay, "ETA too soon");
        bytes32 id = keccak256(abi.encode(target, value, data, eta));
        queued[id] = true;
        emit Queued(id, target, value, data, eta);
    }

    function executeSecure(
        address target, uint256 value, bytes calldata data, uint256 eta
    ) external payable onlyOwner {
        bytes32 id = keccak256(abi.encode(target, value, data, eta));
        require(queued[id], "Not queued");
        require(block.timestamp >= eta, "Too early");
        queued[id] = false;
        (bool ok,) = target.call{ value: value }(data);
        require(ok, "Exec failed");
        emit Executed(id, target, value, data);
    }

    receive() external payable {}
}
