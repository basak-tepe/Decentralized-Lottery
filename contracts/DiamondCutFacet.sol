// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDiamondCut.sol";
import "./libraries/DiamondStorage.sol";

contract DiamondCutFacet is IDiamondCut {
    function diamondCut(FacetCut[] calldata _diamondCut) external override {
        DiamondStorage.DiamondStorageStruct storage ds = DiamondStorage.diamondStorage();
        for (uint256 i = 0; i < _diamondCut.length; i++) {
            address facet = _diamondCut[i].facetAddress;
            for (uint256 j = 0; j < _diamondCut[i].functionSelectors.length; j++) {
                ds.facets[_diamondCut[i].functionSelectors[j]] = facet;
            }
        }
    }
}
