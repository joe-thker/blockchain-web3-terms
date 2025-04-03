// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice ERC223 interface.
interface IERC223 {
    function transfer(address to, uint256 value, bytes calldata data) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}

/// @notice Minimal ERC20 interface.
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/// @notice Interface for a contract that supports receiving ERC223 tokens.
interface IERC223Receiver {
    function tokenFallback(address _from, uint256 _value, bytes calldata _data) external;
}

/// @title DynamicERC223
/// @notice A dynamic, optimized ERC223 token contract that is ERC20-compatible. It supports transfers with data,
/// and if the recipient is a contract, its tokenFallback function is invoked.
contract DynamicERC223 is IERC223, IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    /**
     * @notice Constructor initializes the token with a name, symbol, decimals, and initial supply minted to msg.sender.
     * @param _name Token name.
     * @param _symbol Token symbol.
     * @param _decimals Number of decimal places.
     * @param _initialSupply Initial token supply (in smallest units).
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    /**
     * @notice ERC20 transfer function that calls ERC223 transfer with empty data.
     * @param to The recipient address.
     * @param value The amount of tokens to transfer.
     * @return True if transfer is successful.
     */
    function transfer(address to, uint256 value) external override returns (bool) {
        bytes memory empty;
        return transfer(to, value, empty);
    }

    /**
     * @notice ERC223 transfer function that supports additional data.
     * If the recipient is a contract, it calls its tokenFallback function.
     * @param to The recipient address.
     * @param value The amount of tokens to transfer.
     * @param data Additional data to pass to the recipient.
     * @return True if transfer is successful.
     */
    function transfer(
        address to,
        uint256 value,
        bytes calldata data
    ) public override returns (bool) {
        require(to != address(0), "DynamicERC223: transfer to zero address");
        require(balanceOf[msg.sender] >= value, "DynamicERC223: insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        emit Transfer(msg.sender, to, value, data);

        if (isContract(to)) {
            IERC223Receiver receiver = IERC223Receiver(to);
            receiver.tokenFallback(msg.sender, value, data);
        }
        return true;
    }

    /**
     * @notice Checks if an address is a contract.
     * @param _addr The address to check.
     * @return True if _addr is a contract, false otherwise.
     */
    function isContract(address _addr) internal view returns (bool) {
        return _addr.code.length > 0;
    }
}
