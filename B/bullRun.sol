// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BullRunDictionary
/// @notice This contract stores and retrieves the definition and use cases for a Bull Run in the crypto market.
contract BullRunDictionary {
    address public owner;
    string public term = "Bull Run";
    string public definition;

    event DefinitionUpdated(string newDefinition);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /// @notice Constructor sets the deployer as the owner and initializes the bull run definition.
    constructor() {
        owner = msg.sender;
        definition = "A Bull Run is a prolonged period of significant price increases in the crypto market, driven by positive investor sentiment and strong buying pressure. It attracts new investors, fuels speculative trading, and increases market liquidity.";
    }

    /// @notice Retrieves the definition of Bull Run.
    /// @return The current definition as a string.
    function getDefinition() public view returns (string memory) {
        return definition;
    }

    /// @notice Allows the owner to update the definition of Bull Run.
    /// @param newDefinition The new definition string.
    function updateDefinition(string memory newDefinition) public onlyOwner {
        definition = newDefinition;
        emit DefinitionUpdated(newDefinition);
    }
}
