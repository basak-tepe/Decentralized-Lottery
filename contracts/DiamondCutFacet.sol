// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDiamondCut.sol";
import "./libraries/DiamondStorage.sol";

contract DiamondCutFacet is IDiamondCut {
    /// @notice Implements the `diamondCut` function to manage facets.
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        DiamondStorage.DiamondStorageStruct storage ds = DiamondStorage.diamondStorage();

        for (uint256 i = 0; i < _diamondCut.length; i++) {
            FacetCut memory cut = _diamondCut[i];
            if (cut.action == FacetCutAction.Add) {
                addFunctions(cut.facetAddress, cut.functionSelectors, ds);
            } else if (cut.action == FacetCutAction.Replace) {
                replaceFunctions(cut.facetAddress, cut.functionSelectors, ds);
            } else if (cut.action == FacetCutAction.Remove) {
                removeFunctions(cut.functionSelectors, ds);
            } else {
                revert("DiamondCutFacet: Invalid FacetCutAction");
            }
        }

        emit DiamondCut(_diamondCut, _init, _calldata);

        // Call initialization function, if specified
        if (_init != address(0)) {
            require(_calldata.length > 0, "DiamondCutFacet: _calldata is empty but _init is set");
            (bool success, ) = _init.delegatecall(_calldata);
            require(success, "DiamondCutFacet: Initialization function failed");
        }
    }

    /// @notice Add new functions to the diamond.
    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors, DiamondStorage.DiamondStorageStruct storage ds) internal {
        require(_facetAddress != address(0), "DiamondCutFacet: Facet address cannot be zero");
        for (uint256 i = 0; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            require(ds.facets[selector] == address(0), "DiamondCutFacet: Function already exists");
            ds.facets[selector] = _facetAddress;
        }
    }

    /// @notice Replace existing functions in the diamond.
    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors, DiamondStorage.DiamondStorageStruct storage ds) internal {
        require(_facetAddress != address(0), "DiamondCutFacet: Facet address cannot be zero");
        for (uint256 i = 0; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            require(ds.facets[selector] != address(0), "DiamondCutFacet: Function does not exist");
            ds.facets[selector] = _facetAddress;
        }
    }

    /// @notice Remove functions from the diamond.
    function removeFunctions(bytes4[] memory _functionSelectors, DiamondStorage.DiamondStorageStruct storage ds) internal {
        for (uint256 i = 0; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            require(ds.facets[selector] != address(0), "DiamondCutFacet: Function does not exist");
            ds.facets[selector] = address(0);
        }
    }
}