contract OracleVulnerable {
    address public oracle;
    uint256 public price;

    function updatePrice() external {
        require(msg.sender == oracle);
        price = tx.origin.balance; // ⚠️ Bad source of truth
    }
}
