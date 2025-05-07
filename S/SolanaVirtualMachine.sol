// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SVMSuite
/// @notice Illustrates SVM-style CPI guards, data checks, and rent-exempt account creation in Solidity

abstract contract Base {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    constructor() { owner = msg.sender; }
}

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
// 1) Cross-Program Invocation (CPI)
//////////////////////////////////////////////////////
contract CPIGuard is Base {
    // insecure: allow arbitrary external calls to any programId
    function invokeInsecure(address programId, bytes calldata data) external payable {
        (bool ok, ) = programId.call{value: msg.value}(data);
        require(ok, "CPI failed");
    }

    // secure: only allow calls to a whitelisted programId and check sender
    mapping(address=>bool) public isAllowedProgram;

    function whitelistProgram(address programId, bool ok) external onlyOwner {
        isAllowedProgram[programId] = ok;
    }

    function invokeSecure(address programId, bytes calldata data) external payable {
        require(isAllowedProgram[programId], "Program not allowed");
        // optional: verify that this contract was invoked by a known program via msg.sender
        (bool ok, ) = programId.call{value: msg.value}(data);
        require(ok, "CPI failed");
    }
}

//////////////////////////////////////////////////////
// 2) Account Data Deserialization
//////////////////////////////////////////////////////
contract SerializationGuard is Base {
    struct MyData { uint8 version; uint256 value; }

    // insecure: just ABI-decode data, will revert or mis-parse if too short
    function parseInsecure(bytes calldata data) external pure returns (MyData memory) {
        // if data.length < 33, this will revert
        MyData memory d = abi.decode(data, (MyData));
        return d;
    }

    // secure: check length, magic/version field before decode
    function parseSecure(bytes calldata data) external pure returns (MyData memory) {
        // require at least 1 byte version + 32 byte value
        require(data.length >= 33, "Data too short");
        // peek version byte
        uint8 version = uint8(data[0]);
        require(version == 1, "Unsupported version");
        // safe to decode now
        MyData memory d = abi.decode(data, (MyData));
        return d;
    }
}

//////////////////////////////////////////////////////
// 3) Rent-Exempt Account Creation (PDA-style)
//////////////////////////////////////////////////////
contract PDAFactory is Base, ReentrancyGuard {
    uint256 public minBalance;  // minimum value to fund “rent-exempt” account

    mapping(address=>bool) public isPDA;

    event PDACreated(address pda, address creator, uint256 balance);

    constructor(uint256 _minBalance) {
        minBalance = _minBalance;
    }

    // insecure: allow any creation, no balance check
    function createInsecure(bytes32 seed) external returns (address) {
        address pda = address(uint160(uint256(keccak256(abi.encodePacked(seed, address(this))))));
        isPDA[pda] = true;
        emit PDACreated(pda, msg.sender, address(this).balance);
        return pda;
    }

    // secure: require sufficient funding + validate PDA derivation
    function createSecure(bytes32 seed) external payable nonReentrant returns (address) {
        require(msg.value >= minBalance, "Insufficient funding");
        address pda = address(uint160(uint256(keccak256(abi.encodePacked(seed, address(this))))));
        // ensure unique
        require(!isPDA[pda], "PDA exists");
        isPDA[pda] = true;
        // fund the PDA
        (bool ok, ) = pda.call{value: msg.value}("");
        require(ok, "Funding failed");
        emit PDACreated(pda, msg.sender, msg.value);
        return pda;
    }

    // owner can withdraw excess
    function withdraw(uint256 amt) external onlyOwner {
        payable(owner).transfer(amt);
    }

    receive() external payable {}
}
