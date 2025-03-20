// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IBEP721 Interface
/// @notice Standard interface for BEP‑721 tokens.
interface IBEP721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

/// @title BEP721Token
/// @notice A simple BEP‑721 token implementation for non‑fungible tokens on Binance Smart Chain.
contract BEP721Token is IBEP721 {
    string public name;
    string public symbol;

    // Mapping from token ID to owner.
    mapping(uint256 => address) private _owners;
    // Mapping from owner to token count.
    mapping(address => uint256) private _balances;
    // Mapping from token ID to approved address.
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals.
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 private _currentTokenId;
    address public contractOwner;

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Not contract owner");
        _;
    }

    /// @notice Constructor to initialize the BEP‑721 token.
    /// @param _name The token name.
    /// @param _symbol The token symbol.
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        contractOwner = msg.sender;
    }

    /// @notice Returns the number of tokens owned by `owner`.
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "Invalid address");
        return _balances[owner];
    }

    /// @notice Returns the owner of the token with ID `tokenId`.
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address tokenOwner = _owners[tokenId];
        require(tokenOwner != address(0), "Token does not exist");
        return tokenOwner;
    }

    /// @notice Approves `to` to transfer token with ID `tokenId`.
    function approve(address to, uint256 tokenId) public override {
        address tokenOwner = ownerOf(tokenId);
        require(to != tokenOwner, "Approval to current owner");
        require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender), "Not authorized");

        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    /// @notice Returns the approved address for token ID `tokenId`.
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenApprovals[tokenId];
    }

    /// @notice Sets or unsets the approval of a given operator.
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "Approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Returns if the operator is allowed to manage all of the assets of owner.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @notice Transfers token with ID `tokenId` from `from` to `to`.
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        _transfer(from, to, tokenId);
    }

    /// @notice Safely transfers token with ID `tokenId` from `from` to `to`.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @notice Safely transfers token with ID `tokenId` from `from` to `to` with additional data.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        transferFrom(from, to, tokenId);
        require(_checkOnBEP721Received(from, to, tokenId, _data), "Transfer to non BEP721Receiver implementer");
    }

    /// @notice Mints a new token and assigns it to `to`.
    function mint(address to) public onlyOwner {
        require(to != address(0), "Mint to zero address");
        _currentTokenId++;
        uint256 newTokenId = _currentTokenId;
        _owners[newTokenId] = to;
        _balances[to] += 1;
        emit Transfer(address(0), to, newTokenId);
    }

    /// @notice Internal function to check if token exists.
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /// @notice Internal function to determine if `spender` is owner or approved.
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        address tokenOwner = ownerOf(tokenId);
        return (spender == tokenOwner || getApproved(tokenId) == spender || isApprovedForAll(tokenOwner, spender));
    }

    /// @notice Internal function to perform token transfer.
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "Not token owner");
        require(to != address(0), "Transfer to zero address");

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    /// @notice Internal function to set token approval.
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /// @notice Internal function to check BEP721Receiver interface.
    function _checkOnBEP721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
            try IBEP721Receiver(to).onBEP721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IBEP721Receiver(to).onBEP721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Transfer to non BEP721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /// @notice Returns true if `account` is a contract.
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

/// @title IBEP721Receiver
/// @notice Interface for contracts that support safe transfers from BEP-721 asset contracts.
interface IBEP721Receiver {
    function onBEP721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
