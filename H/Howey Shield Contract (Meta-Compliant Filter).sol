contract HoweyShield {
    struct TokenMeta {
        bool noInvestment;
        bool noProfit;
        bool decentralized;
        bool noPooling;
    }

    mapping(address => TokenMeta) public tokens;

    function registerToken(address token, bool noInvestment, bool noProfit, bool decentralized, bool noPooling) external {
        tokens[token] = TokenMeta(noInvestment, noProfit, decentralized, noPooling);
    }

    function isLikelyCompliant(address token) external view returns (bool) {
        TokenMeta memory meta = tokens[token];
        return meta.noInvestment && meta.noProfit && meta.decentralized && meta.noPooling;
    }
}
