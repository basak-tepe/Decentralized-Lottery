// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDiamondCut {
    struct FacetCut {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    function diamondCut(FacetCut[] calldata _diamondCut) external;
}