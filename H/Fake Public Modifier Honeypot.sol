contract ModifierTrap {
    address public owner = msg.sender;

    modifier publicOnly() {
        require(tx.origin == owner, "Nice try");
        _;
    }

    function claimBounty() publicOnly public {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}
