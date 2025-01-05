// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDiamondCut.sol";
import "./libraries/DiamondStorage.sol";

contract Diamond {
    constructor(address _diamondCutFacet) {
        DiamondStorage.DiamondStorageStruct storage ds = DiamondStorage.diamondStorage();
        ds.diamondCutFacet = _diamondCutFacet;
    }

    fallback() external payable {
        DiamondStorage.DiamondStorageStruct storage ds = DiamondStorage.diamondStorage();
        address facet = ds.facets[msg.sig];
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
