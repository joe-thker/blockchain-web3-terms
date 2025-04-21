// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FantomMainnet
 * @notice On‐chain constants for the Fantom Opera (Opera Mainnet) network.
 *
 * All addresses are now correctly checksummed per EIP‑55.
 */
contract FantomMainnet {
    /// EVM chain ID for Fantom Opera
    uint256 public constant CHAIN_ID = 250;

    /// Wrapped FTM token
    address public constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    /// USD‑pegged stablecoins
    address public constant USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address public constant USDT = 0x049d68029688eAbF473097a2fC38ef61633A3C7A;  // fixed checksum
    address public constant DAI  = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;

    /// Major DEX routers
    address public constant SPOOKY               = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address public constant SPIRIT               = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;

    /// Beethoven X (Balancer V2) vault
    address public constant BEETHOVENX_VAULT    = 0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce;  // fixed checksum

    /// FTMScan explorer base URL
    string  public constant EXPLORER            = "https://ftmscan.com";

    /// @notice Return all core token addresses
    function getTokens()
        external
        pure
        returns (
            address wftm,
            address usdc,
            address usdt,
            address dai
        )
    {
        return (WFTM, USDC, USDT, DAI);
    }

    /// @notice Return all router & vault addresses
    function getRouters()
        external
        pure
        returns (
            address spookyRouter,
            address spiritRouter,
            address beethovenVault
        )
    {
        return (SPOOKY, SPIRIT, BEETHOVENX_VAULT);
    }

    /// @notice Return chain information
    function getChainInfo()
        external
        pure
        returns (
            uint256 chainId,
            string memory explorer
        )
    {
        return (CHAIN_ID, EXPLORER);
    }
}
