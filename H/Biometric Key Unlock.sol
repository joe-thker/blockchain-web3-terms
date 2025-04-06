contract BiometricKeyVault {
    address public trustedDevice;

    constructor(address _device) {
        trustedDevice = _device;
    }

    function unlock(bytes32 hash, bytes calldata signature) external view returns (bool) {
        return recoverSigner(hash, signature) == trustedDevice;
    }

    function recoverSigner(bytes32 hash, bytes memory sig) internal pure returns (address) {
        return ECDSA.recover(hash, sig); // From OpenZeppelin’s ECDSA lib
    }
}
