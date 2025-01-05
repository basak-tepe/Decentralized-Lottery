// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDiamondLoupe {
    function facetAddress(bytes4 _functionSelector) external view returns (address);
    function facetAddresses() external view returns (address[] memory);
}