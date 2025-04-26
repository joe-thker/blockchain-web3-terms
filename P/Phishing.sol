// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PhishSafeFilter
 * @notice Library providing a helper to extract the domain from a URL string.
 */
library PhishSafeFilter {
    /**
     * @notice Extracts the domain (host) portion of a URL.
     * @param link The full URL (e.g. "https://example.com/path").
     * @return domain The extracted domain (e.g. "example.com").
     */
    function extractDomain(string memory link) internal pure returns (string memory domain) {
        bytes memory linkBytes = bytes(link);
        uint256 length = linkBytes.length;
        uint256 start = 0;

        // Skip "http://" or "https://"
        if (length >= 7 && linkBytes[0] == "h" && linkBytes[1] == "t" && linkBytes[2] == "t" && linkBytes[3] == "p") {
            for (uint256 i = 0; i + 2 < length; i++) {
                if (linkBytes[i] == ":" && linkBytes[i+1] == "/" && linkBytes[i+2] == "/") {
                    start = i + 3;
                    break;
                }
            }
        }

        // Find end of domain (first '/' or ':' after start)
        uint256 end = length;
        for (uint256 i = start; i < length; i++) {
            bytes1 b = linkBytes[i];
            if (b == "/" || b == ":") {
                end = i;
                break;
            }
        }

        // Copy out the domain bytes
        uint256 domainLength = end - start;
        bytes memory domainBytes = new bytes(domainLength);
        for (uint256 i = 0; i < domainLength; i++) {
            domainBytes[i] = linkBytes[start + i];
        }

        domain = string(domainBytes);
    }
}

/**
 * @title PhishingDetector
 * @notice Example contract that uses PhishSafeFilter to parse URLs.
 */
contract PhishingDetector {
    /**
     * @notice Checks whether a URL’s domain appears on a hypothetical blocklist.
     * @param url The full URL to check.
     * @return blocked True if the domain is on the blocklist; false otherwise.
     */
    function isBlocked(string calldata url) external pure returns (bool blocked) {
        // Extract the domain using the library
        string memory domain = PhishSafeFilter.extractDomain(url);

        // For demo purposes, block "malicious.com" only
        // In practice you’d check against a stored mapping or oracle
        if (keccak256(bytes(domain)) == keccak256(bytes("malicious.com"))) {
            return true;
        }
        return false;
    }
}
