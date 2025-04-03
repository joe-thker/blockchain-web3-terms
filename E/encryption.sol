pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
/// @title EncryptionDemo
/// @notice This contract demonstrates a simple symmetric encryption mechanism using an XOR cipher.
/// The owner can set a stored key and then encrypt or decrypt data with that key.
contract EncryptionDemo is Ownable {
    bytes private storedKey;
event KeyUpdated(bytes newKey);
constructor() Ownable(msg.sender) {}
function setKey(bytes calldata newKey) external onlyOwner {
        require(newKey.length > 0, "Key must not be empty");
        storedKey = newKey;
        emit KeyUpdated(newKey);
    }
function xorEncrypt(bytes memory data, bytes memory key) public pure returns (bytes memory result) {
        require(key.length > 0, "Key must not be empty");
        result = new bytes(data.length);
        for (uint256 i = 0; i < data.length; i++) {
            result[i] = bytes1(uint8(data[i]) ^ uint8(key[i % key.length]));
        }
    }
function encrypt(bytes memory data) external view returns (bytes memory) {
        require(storedKey.length > 0, "Encryption key not set");
        return xorEncrypt(data, storedKey);
    }
function decrypt(bytes memory encryptedData) external view returns (bytes memory) {
        require(storedKey.length > 0, "Encryption key not set");
        return xorEncrypt(encryptedData, storedKey);
    }
}
