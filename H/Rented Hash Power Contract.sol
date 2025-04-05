contract RentedHashPower {
    mapping(address => uint256) public rentedPower;

    function rentPower(uint256 amount) external payable {
        require(msg.value >= amount * 1e14, "Pay per power unit"); // e.g., 0.0001 ETH per unit
        rentedPower[msg.sender] += amount;
    }

    function getRentedPower(address user) public view returns (uint256) {
        return rentedPower[user];
    }
}
