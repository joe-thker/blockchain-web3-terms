// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Web3FoundationGrants {
    address public immutable foundationCouncil;

    struct Grant {
        uint256 total;
        uint256 released;
        address recipient;
        bool active;
    }

    mapping(bytes32 => Grant) public grants;

    event GrantCreated(bytes32 indexed id, address recipient, uint256 total);
    event GrantPaid(bytes32 indexed id, uint256 amount);

    modifier onlyFoundation() {
        require(msg.sender == foundationCouncil, "Not foundation");
        _;
    }

    constructor(address _council) {
        foundationCouncil = _council;
    }

    function createGrant(bytes32 id, address recipient, uint256 amount) external onlyFoundation {
        require(grants[id].recipient == address(0), "Grant exists");
        grants[id] = Grant({
            total: amount,
            released: 0,
            recipient: recipient,
            active: true
        });
        emit GrantCreated(id, recipient, amount);
    }

    function releaseMilestone(bytes32 id, uint256 amount) external onlyFoundation {
        Grant storage g = grants[id];
        require(g.active, "Inactive grant");
        require(g.released + amount <= g.total, "Exceeds grant");

        g.released += amount;
        (bool ok, ) = g.recipient.call{value: amount}("");
        require(ok, "Transfer failed");

        emit GrantPaid(id, amount);
    }

    function deactivateGrant(bytes32 id) external onlyFoundation {
        grants[id].active = false;
    }

    receive() external payable {}
}
