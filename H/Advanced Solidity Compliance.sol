contract TokenComplianceRegistry {
    mapping(address => bool) public isHoweyCompliant;

    event Flagged(address indexed token, bool compliant);

    function setCompliance(address token, bool compliant) external {
        isHoweyCompliant[token] = compliant;
        emit Flagged(token, compliant);
    }

    function checkCompliance(address token) external view returns (bool) {
        return isHoweyCompliant[token];
    }
}
