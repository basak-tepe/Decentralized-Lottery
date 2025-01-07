// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDiamondCut.sol";

contract DiamondSetup {

    function setupDiamond(
        address diamondAddress,
        address lotteryManagementFacet/*,
        address paymentFacet,
        address ticketManagementFacet,
        address winnerDeterminationFacet,
        address accessControlFacet*/
    ) external {
        // Initialize selectors for LotteryManagementFacet

        bytes4[] memory lotterySelectors;
        lotterySelectors = new bytes4[](8);
        lotterySelectors[0] = bytes4(keccak256("createLottery(uint,uint,uint,uint,uint,bytes32,string)"));
        lotterySelectors[1] = bytes4(keccak256("getLotteryInfo(uint256)"));
        lotterySelectors[2] = bytes4(keccak256("getLotteryState(uint256)"));
        lotterySelectors[3] = bytes4(keccak256("updateLotteryStates()"));
        lotterySelectors[4] = bytes4(keccak256("getIthPurchasedTicketTx(uint,uint)"));
        lotterySelectors[5] = bytes4(keccak256("getNumPurchaseTxs(uint)"));
        lotterySelectors[6] = bytes4(keccak256("getLotteryURL(uint)"));
        lotterySelectors[7] = bytes4(keccak256("getLotterySales(uint)"));

        IDiamondCut.FacetCut[] memory fc;
        fc = new IDiamondCut.FacetCut[](1);

        fc[0] = IDiamondCut.FacetCut({
            facetAddress: lotteryManagementFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: lotterySelectors
        });

        /*
        // Initialize selectors for PaymentFacet
        bytes4;
        paymentSelectors[0] = bytes4(keccak256("setPaymentToken(address)"));
        paymentSelectors[1] = bytes4(keccak256("getPaymentToken(uint)"));
        paymentSelectors[2] = bytes4(keccak256("withdrawTicketProceeds(uint)"));

        // Initialize selectors for TicketManagementFacet
        bytes4;
        ticketSelectors[0] = bytes4(keccak256("buyTicketTx(uint,uint,bytes32)"));
        ticketSelectors[1] = bytes4(keccak256("revealRndNumberTx(uint,uint,uint)"));
        ticketSelectors[2] = bytes4(keccak256("withdrawTicketRefund(uint,uint)"));

        // Initialize selectors for WinnerDeterminationFacet
        bytes4;
        winnerSelectors[0] = bytes4(keccak256("determineWinners(uint256)"));
        winnerSelectors[1] = bytes4(keccak256("getIthWinningTicket(uint,uint)"));
        winnerSelectors[2] = bytes4(keccak256("checkIfMyTicketWon(uint,uint)"));
        winnerSelectors[3] = bytes4(keccak256("checkIfAddrTicketWon(address,uint,uint)"));

        // Initialize selectors for AccessControlFacet
        bytes4;
        accessControlSelectors[0] = bytes4(keccak256("initializeAccessControl(address)"));
        accessControlSelectors[1] = bytes4(keccak256("getOwner()"));

        // Create the FacetCut array
        IDiamondCut.FacetCut;

        fc[0] = IDiamondCut.FacetCut({
            facetAddress: lotteryManagementFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: lotterySelectors
        });

        fc[1] = IDiamondCut.FacetCut({
            facetAddress: paymentFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: paymentSelectors
        });

        fc[2] = IDiamondCut.FacetCut({
            facetAddress: ticketManagementFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ticketSelectors
        });

        fc[3] = IDiamondCut.FacetCut({
            facetAddress: winnerDeterminationFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: winnerSelectors
        });

        fc[4] = IDiamondCut.FacetCut({
            facetAddress: accessControlFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: accessControlSelectors
        });
        */
        // Call diamondCut to add all facets
        IDiamondCut(diamondAddress).diamondCut(
            fc,
            address(0), // No initialization
            ""          // No calldata
        );
    }
}