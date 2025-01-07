// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DiamondStorage {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorageStruct {
        mapping(bytes4 => address) facets;         // Maps function selectors to facet addresses
        address[] facetAddresses;                  // Array of facet addresses
        mapping(address => bytes4[]) selectors;    // Maps facet address to its function selectors
        address diamondCutFacet;                   // Address of the DiamondCut facet
        uint256 facetCount;                        // Count of facets
    }

    /**
     * @dev Returns the storage pointer for DiamondStorage.
     */
    function diamondStorage() internal pure returns (DiamondStorageStruct storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}