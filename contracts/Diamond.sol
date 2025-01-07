// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/DiamondStorage.sol";

contract Diamond {
    constructor(
        address _diamondCutFacet,
        address _lotteryManagementFacet,
        address _paymentFacet,
        address _ticketManagementFacet,
        address _winnerDeterminationFacet,
        address _accessControlFacet
    ) {
        DiamondStorage.DiamondStorageStruct storage ds = DiamondStorage.diamondStorage();

        ds.diamondCutFacet = _diamondCutFacet; // Set the DiamondCut facet address

        // Initialize facets and their selectors
        _addFacet(_lotteryManagementFacet, _getLotteryManagementSelectors());
        _addFacet(_paymentFacet, _getPaymentSelectors());
        _addFacet(_ticketManagementFacet, _getTicketManagementSelectors());
        _addFacet(_winnerDeterminationFacet, _getWinnerDeterminationSelectors());
        _addFacet(_accessControlFacet, _getAccessControlSelectors());
        
    }

    // Add facet functions
    function _addFacet(address facetAddress, bytes4[] memory selectors) internal {
        DiamondStorage.DiamondStorageStruct storage ds = DiamondStorage.diamondStorage();

        require(facetAddress != address(0), "Facet address cannot be zero");
        ds.facetAddresses.push(facetAddress);

        for (uint256 i = 0; i < selectors.length; i++) {
            ds.facets[selectors[i]] = facetAddress;
            ds.selectors[facetAddress].push(selectors[i]);
        }
    }

    function _getLotteryManagementSelectors() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](1);
        selectors[0] = bytes4(keccak256("createLottery(uint,uint,uint,uint,uint,bytes32,string)"));
        selectors[1] = bytes4(keccak256("getLotteryInfo(uint256)"));
        selectors[2] = bytes4(keccak256("getLotteryState(uint256)"));
        selectors[3] = bytes4(keccak256("updateLotteryStates()"));
        selectors[4] = bytes4(keccak256("getIthPurchasedTicketTx(uint,uint)"));
        selectors[5] = bytes4(keccak256("getNumPurchaseTxs(uint)"));
        selectors[6] = bytes4(keccak256("getLotteryURL(uint)"));
        selectors[7] = bytes4(keccak256("getLotterySales(uint)"));
        return selectors;
    }

    function _getPaymentSelectors() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](3);
        selectors[0] = bytes4(keccak256("setPaymentToken(address)"));
        selectors[1] = bytes4(keccak256("getPaymentToken(uint256)"));
        selectors[2] = bytes4(keccak256("withdrawTicketProceeds(uint256)"));
        return selectors;
    }

    function _getTicketManagementSelectors() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](3);
        selectors[0] = bytes4(keccak256("buyTicketTx(uint256,uint256,bytes32)"));
        selectors[1] = bytes4(keccak256("revealRndNumberTx(uint256,uint256,uint256)"));
        selectors[2] = bytes4(keccak256("withdrawTicketRefund(uint256,uint256)"));
        return selectors;
    }

    function _getWinnerDeterminationSelectors() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](4);
        selectors[0] = bytes4(keccak256("determineWinners(uint256)"));
        selectors[1] = bytes4(keccak256("getIthWinningTicket(uint256,uint256)"));
        selectors[2] = bytes4(keccak256("checkIfMyTicketWon(uint256,uint256)"));
        selectors[3] = bytes4(keccak256("checkIfAddrTicketWon(address,uint256,uint256)"));
        return selectors;
    }

    function _getAccessControlSelectors() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](2);
        selectors[0] = bytes4(keccak256("initializeAccessControl(address)"));
        selectors[1] = bytes4(keccak256("getOwner()"));
        return selectors;
    }

    /// @notice Fallback function for handling external calls
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

    /// @notice Receive function for handling direct Ether transfers
    receive() external payable {}
}