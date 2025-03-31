// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DataScraping
/// @notice This contract allows authorized addresses to update scraped data for a given key.
/// The owner can manage authorized scrapers, and the stored data is available to anyone.
contract DataScraping is Ownable, ReentrancyGuard {
    // Mapping from a key (e.g., a URL or data label) to its scraped data (as a string).
    mapping(string => string) private scrapedData;
    
    // Mapping for addresses authorized to update (scrape) data.
    mapping(address => bool) public authorizedScrapers;
    
    // --- Events ---
    event ScraperAuthorized(address indexed scraper);
    event ScraperRevoked(address indexed scraper);
    event DataUpdated(string indexed key, string data, uint256 timestamp);

    /// @notice Modifier to restrict functions to only the owner or an authorized scraper.
    modifier onlyScraper() {
        require(authorizedScrapers[msg.sender] || msg.sender == owner(), "Not an authorized scraper");
        _;
    }

    /// @notice Constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {
        // No additional initialization required.
    }

    /// @notice Authorizes an address to update scraped data.
    /// @param scraper The address to authorize.
    function authorizeScraper(address scraper) external onlyOwner {
        require(scraper != address(0), "Invalid scraper address");
        authorizedScrapers[scraper] = true;
        emit ScraperAuthorized(scraper);
    }

    /// @notice Revokes an address's permission to update scraped data.
    /// @param scraper The address to revoke.
    function revokeScraper(address scraper) external onlyOwner {
        require(authorizedScrapers[scraper], "Scraper not authorized");
        authorizedScrapers[scraper] = false;
        emit ScraperRevoked(scraper);
    }

    /// @notice Updates the scraped data for a given key.
    /// @param key The identifier for the data (e.g., a URL or label).
    /// @param data The scraped data as a string.
    function updateData(string calldata key, string calldata data) external onlyScraper nonReentrant {
        require(bytes(key).length > 0, "Key cannot be empty");
        scrapedData[key] = data;
        emit DataUpdated(key, data, block.timestamp);
    }

    /// @notice Retrieves the scraped data for a given key.
    /// @param key The identifier for the data.
    /// @return The stored data as a string.
    function getData(string calldata key) external view returns (string memory) {
        return scrapedData[key];
    }
}
