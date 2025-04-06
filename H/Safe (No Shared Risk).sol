contract PersonalAccessToken {
    mapping(address => bool) public access;

    function activate() external payable {
        require(msg.value == 0.01 ether, "Fixed cost");
        access[msg.sender] = true;
    }

    function useService() external view returns (string memory) {
        require(access[msg.sender], "No access");
        return "You are using the service!";
    }
}
