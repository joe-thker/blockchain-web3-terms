// Vulnerable only in pre-0.8.0
contract OverflowExample {
    uint256 public total;

    function add(uint256 amount) public {
        total += amount; // ⚠️ Could overflow in Solidity < 0.8
    }
}
