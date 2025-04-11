contract EVMMainChain {
    mapping(address => bool) public allowedContracts;

    function registerApp(address app) external {
        allowedContracts[app] = true;
    }

    function executeAppTx(address app, bytes calldata data) external {
        require(allowedContracts[app], "App not registered");
        (bool success, ) = app.call(data);
        require(success, "Tx failed");
    }
}
