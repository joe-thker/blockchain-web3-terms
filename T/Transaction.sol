// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TransactionModule - Simulates TX Types, Attacks, and Defenses

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
}

/// 🧾 Simple Receiver Contract
contract TXReceiver {
    uint256 public balance;

    function deposit() external payable {
        balance += msg.value;
    }

    function withdraw(address payable to, uint256 amt) external {
        require(balance >= amt, "Too much");
        balance -= amt;
        to.transfer(amt);
    }
}

/// 🛡️ Protected Contract with Reentrancy + Deadline + Slippage Checks
abstract contract ReentrancyGuard {
    bool private locked;
    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }
}

contract TXProtectedContract is ReentrancyGuard {
    uint256 public price = 1 ether;

    function secureBuy(uint256 maxPrice, uint256 deadline) external payable nonReentrant {
        require(block.timestamp <= deadline, "Expired");
        require(msg.value >= price, "Price too low");
        require(price <= maxPrice, "Slippage breach");

        // Secure purchase logic
    }
}

/// 🔓 TX Attacker: Tries to reenter and front-run
contract TXAttacker {
    TXReceiver public target;

    constructor(address _target) {
        target = TXReceiver(_target);
    }

    receive() external payable {
        if (address(target).balance >= 1 ether) {
            target.withdraw(payable(address(this)), 1 ether);
        }
    }

    function attack() external payable {
        require(msg.value >= 1 ether);
        target.deposit{value: 1 ether}();
        target.withdraw(payable(address(this)), 1 ether);
    }
}

/// ✍️ Meta-Transaction Forwarder (EIP-712 Style)
contract MetaTXForwarder {
    mapping(address => uint256) public nonces;

    function executeMetaTX(
        address user,
        address to,
        bytes calldata data,
        uint256 nonce,
        bytes calldata sig
    ) external {
        require(nonce == nonces[user], "Invalid nonce");

        bytes32 hash = keccak256(abi.encodePacked(user, to, data, nonce));
        address signer = recover(hash, sig);
        require(signer == user, "Invalid signer");

        nonces[user]++;
        (bool ok, ) = to.call(data);
        require(ok, "MetaTX failed");
    }

    function recover(bytes32 h, bytes memory sig) internal pure returns (address) {
        bytes32 m = prefixed(h);
        (uint8 v, bytes32 r, bytes32 s) = split(sig);
        return ecrecover(m, v, r, s);
    }

    function prefixed(bytes32 h) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }

    function split(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65, "Bad sig");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
