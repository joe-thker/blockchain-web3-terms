pragma solidity ^0.8.20;

contract RollupGenesis {
    bytes32 public genesisRoot;
    address public sequencer;

    constructor(bytes32 _root, address _sequencer) {
        genesisRoot = _root;
        sequencer = _sequencer;
    }

    function verifyInitialState(bytes32 state) external view returns (bool) {
        return state == genesisRoot;
    }
}
