// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DiamondStorage {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorageStruct {
        mapping(bytes4 => address) facets;
        mapping(uint256 => address) facetAddresses;
        uint256 facetCount;
        address diamondCutFacet;
    }

    function diamondStorage() internal pure returns (DiamondStorageStruct storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}