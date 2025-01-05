// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LotteryStorage.sol";

/**
 * AccessControlFacet
 * Facet responsible for managing role-based access control in a Diamond architecture.
 */
contract AccessControlFacet {
    /**
     * Modifier to restrict access to the contract owner.
     */
    modifier onlyOwner() {
        require(msg.sender == getOwner(), "AccessControl: Caller is not the owner");
        _;
    }

    /**
     * Sets the initial owner during the facet initialization.
     * Can only be called once.
     * @param _owner The address of the new owner.
     */
    function initializeAccessControl(address _owner) external {
        LotteryStorage.State storage s = LotteryStorage.getStorage();
        require(!s.accessControlInitialized, "AccessControl: Already initialized");
        require(_owner != address(0), "AccessControl: Invalid owner address");

        s.owner = _owner;
        s.accessControlInitialized = true;
    }

    /**
     * Returns the address of the contract owner.
     * @return The owner's address.
     */
    function getOwner() public view returns (address) {
        LotteryStorage.State storage s = LotteryStorage.getStorage();
        return s.owner;
    }
}