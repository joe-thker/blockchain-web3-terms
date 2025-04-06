// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HiddenCapSale {
    address public owner;
    bytes32 public committedHash; // keccak256(secret + cap)
    uint256 public revealedCap;
    bool public capRevealed;
    bool public paused;

    uint256 public totalRaised;
    mapping(address => uint256) public contributions;

    event Committed(bytes32 hash);
    event Revealed(uint256 cap);
    event Contribution(address user, uint256 amount);
    event Paused();

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(bytes32 _committedHash) {
        owner = msg.sender;
        committedHash = _committedHash;
        emit Committed(_committedHash);
    }

    receive() external payable {
        require(!paused, "Sale paused");
        require(!capRevealed || totalRaised + msg.value <= revealedCap, "Exceeds cap");

        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
        emit Contribution(msg.sender, msg.value);
    }

    /// @notice Reveal secret + cap to validate the committed hash
    function revealCap(string memory secret, uint256 cap) external onlyOwner {
        require(!capRevealed, "Already revealed");
        require(keccak256(abi.encodePacked(secret, cap)) == committedHash, "Invalid reveal");

        revealedCap = cap;
        capRevealed = true;

        emit Revealed(cap);
    }

    /// @notice Emergency pause
    function pauseSale() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
