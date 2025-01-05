// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDiamondLoupe.sol";
import "./libraries/DiamondStorage.sol";

contract DiamondLoupeFacet is IDiamondLoupe {
    function facetAddress(bytes4 _functionSelector) external view override returns (address) {
        return DiamondStorage.diamondStorage().facets[_functionSelector];
    }

    function facetAddresses() external view override returns (address[] memory) {
        DiamondStorage.DiamondStorageStruct storage ds = DiamondStorage.diamondStorage();
        uint256 count = ds.facetCount;
        address[] memory addresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            addresses[i] = ds.facetAddresses[i];
        }
        return addresses;
    }
}