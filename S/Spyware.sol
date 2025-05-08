// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SpywareSuite
/// @notice Insecure vs. Secure patterns demonstrating common on-chain “spyware” tactics

abstract contract Base {
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
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

//////////////////////////////////////////////
// 1) Data Exfiltration Hook
//////////////////////////////////////////////
contract Exfiltration is Base {
    mapping(address=>uint256) private balances;
    mapping(address=>bool) public authorized;

    event DataLeaked(address indexed user, uint256 balance);

    // --- Attack: anyone can call leakData and learn others’ balances
    function leakDataInsecure(address user) external {
        // no auth check
        emit DataLeaked(user, balances[user]);
    }

    // --- Defense: restrict to authorized viewers only
    function leakDataSecure(address user) external view returns(uint256) {
        require(authorized[msg.sender], "Not authorized");
        return balances[user];
    }

    // Helpers
    function setAuth(address who, bool ok) external onlyOwner {
        authorized[who] = ok;
    }
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
    function balanceOf(address user) external view returns(uint256) {
        return balances[user];
    }
}

//////////////////////////////////////////////
// 2) Malicious Callback Listener
//////////////////////////////////////////////
interface IHook {
    function onAction(bytes calldata data) external;
}

contract CallbackSpy is Base, ReentrancyGuard {
    mapping(address=>bool) public hookAllowed;

    event ActionCalled(address indexed user, bytes data);

    // --- Attack: accept any callback and invoke untrusted logic
    function actInsecure(address hook, bytes calldata data) external {
        // no whitelist, so hook may steal funds or data
        IHook(hook).onAction(data);
        emit ActionCalled(hook, data);
    }

    // --- Defense: whitelist + reentrancy guard + ERC165 check
    function actSecure(address hook, bytes calldata data) external nonReentrant {
        require(hookAllowed[hook], "Hook not allowed");
        // verify ERC165 support for onAction selector
        bytes4 IID = type(IHook).interfaceId;
        (bool ok, bytes memory ret) = hook.staticcall(
            abi.encodeWithSelector(0x01ffc9a7, IID)
        );
        require(ok && abi.decode(ret,(bool)), "Invalid hook");
        IHook(hook).onAction(data);
        emit ActionCalled(hook, data);
    }

    function setHook(address hook, bool ok) external onlyOwner {
        hookAllowed[hook] = ok;
    }
}

//////////////////////////////////////////////
// 3) Hidden Fee Extractor
//////////////////////////////////////////////
contract FeeToken is Base, ReentrancyGuard {
    string  public name = "SpyToken";
    mapping(address=>uint256) public balanceOf;
    uint256 public feeRateBP;  // hidden fee in basis points
    mapping(address=>bool) public optedIn;

    event Transfer(address indexed from, address indexed to, uint256 value, uint256 fee);

    constructor(uint256 _feeBP) {
        feeRateBP = _feeBP; // e.g. 100 = 1%
    }

    // --- Attack: silently deduct fee without user consent
    function transferInsecure(address to, uint256 amt) external {
        uint256 fee = amt * feeRateBP / 10000;
        uint256 net = amt - fee;
        // no opt-in or notice
        balanceOf[msg.sender] -= amt;
        balanceOf[to]          += net;
        balanceOf[owner]       += fee;
        emit Transfer(msg.sender, to, net, fee);
    }

    // --- Defense: require opt-in then apply transparent fee
    function transferSecure(address to, uint256 amt) external nonReentrant {
        require(optedIn[msg.sender], "Not opted in for fee");
        uint256 fee = amt * feeRateBP / 10000;
        uint256 net = amt - fee;
        require(balanceOf[msg.sender] >= amt, "Insufficient");
        // Effects
        balanceOf[msg.sender] -= amt;
        balanceOf[to]          += net;
        balanceOf[owner]       += fee;
        // Interaction
        emit Transfer(msg.sender, to, net, fee);
    }

    // Users must explicitly opt in to pay fees
    function optInFees() external {
        optedIn[msg.sender] = true;
    }

    // Mint for testing
    function mint(address to, uint256 amt) external onlyOwner {
        balanceOf[to] += amt;
    }
}
