// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDiamondCut {
    /// Enum for FacetCut actions: Add, Replace, or Remove functions.
    enum FacetCutAction { Add, Replace, Remove }

    /// Struct to define a single facet cut.
    struct FacetCut {
        address facetAddress;        // The address of the facet.
        FacetCutAction action;       // The action to perform (Add, Replace, Remove).
        bytes4[] functionSelectors;  // The list of function selectors for the action.
    }

    /**
     * Add/replace/remove any number of functions and optionally execute a function with delegatecall
     * @param _diamondCut The array of FacetCut structs.
     * @param _init The address of the contract or facet to execute `_calldata`.
     * @param _calldata The function call, including selector and arguments, to execute on `_init`.
     */
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    /**
     * Emitted when the diamondCut function is called.
     * @param _diamondCut The array of FacetCut structs.
     * @param _init The address of the contract or facet executed with delegatecall.
     * @param _calldata The calldata passed to the _init function.
     */
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}