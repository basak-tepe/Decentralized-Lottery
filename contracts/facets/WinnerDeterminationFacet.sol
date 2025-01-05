// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LotteryStorage.sol";
import "../libraries/LotteryStructs.sol";
import "./AccessControlFacet.sol";

/**
 * WinnerDeterminationFacet
 * Facet responsible for determining and retrieving lottery winners in a Diamond architecture.
 */
contract WinnerDeterminationFacet {

    /**
     * Event emitted when winners are determined.
     * @param lottery_no The ID of the lottery.
     * @param winners Array of winning ticket indices.
     */
    event WinnersDetermined(uint256 indexed lottery_no, uint256[] winners);

    // Modifier to control functions that can be called by the owner only
    modifier onlyOwner() {
        require(msg.sender == AccessControlFacet(address(this)).getOwner(), "Only the owner can call this function");
        _;
    }

    // Modifier to control lottery number
    modifier lotteryControl(uint lottery_no) {
        LotteryStorage.State storage s = LotteryStorage.getStorage();
        require(lottery_no > 0 && lottery_no-1 <= s.currentLotteryNo, "Invalid lottery number");
        _;
    }

    /**
    * Determines the winners of a specific lottery. This function assumes that winners are selected
    * based on a predetermined random number or another method.
    * @param lottery_no The ID of the lottery for which the winners will be determined.
    */
    function determineWinners(uint256 lottery_no)
        external
        onlyOwner
        lotteryControl(lottery_no) {

        LotteryStorage.State storage s = LotteryStorage.getStorage();
        LotteryStructs.Lottery storage lottery = s.lotteries[lottery_no-1];

        require(lottery.state == LotteryStructs.LotteryState.COMPLETED, "Lottery has not been completed");

        // Ensure enough tickets were sold if a minimum percentage is required
        uint256 minTicketsRequired = (lottery.nooftickets * lottery.minpercentage) / 100;
        require(lottery.numsold >= minTicketsRequired, "Not enough tickets sold");

        uint256 totalTickets = lottery.numsold;
        uint256 numWinners = lottery.noofwinners;
        uint256 randomSeed = lottery.currentRandom; // Use currentRandom as the seed for winner determination

        // Select winners
        for (uint256 i = 0; i < numWinners; i++) {
            // Generate a pseudo-random number
            uint256 winnerIndex = uint256(keccak256(abi.encodePacked(randomSeed, i))) % totalTickets;

            // Ensure the winner is unique
            while (_isDuplicateWinner(lottery.lotteryWinners, winnerIndex)) {
                winnerIndex = (winnerIndex + 1) % totalTickets;
            }
            
            // Add the winner to the list
            lottery.lotteryWinners[i] = winnerIndex;
        }

        // Update lottery state to COMPLETED
        lottery.state = LotteryStructs.LotteryState.COMPLETED;

        // Emit an event for winner determination
        emit WinnersDetermined(lottery_no, lottery.lotteryWinners);
    }

    /**
    * Retrieves the ticket number of the i-th winning ticket in a specific lottery.
    * @param lottery_no The ID of the lottery.
    * @param i The index of the winning ticket (starting from 1 for the first winner).
    * @return ticketno The ticket number of the i-th winner.
    */
    function getIthWinningTicket(
        uint lottery_no, 
        uint i
    )   public
        view
        lotteryControl(lottery_no)
        returns (uint ticketno) {

        LotteryStorage.State storage s = LotteryStorage.getStorage();
        LotteryStructs.Lottery storage lottery = s.lotteries[lottery_no-1];

        require(lottery.state == LotteryStructs.LotteryState.COMPLETED, "Lottery has not been completed");
        require(i > 0 && i <= lottery.noofwinners, "Invalid winner index");

        return lottery.lotteryWinners[i - 1]; // Adjust for 0-based index
    }

    /**
    * Function to check if a specific ticket has won in a specified lottery.
    * This function assumes the winners are determined and marked in some way 
    * @param lottery_no The ID of the lottery.
    * @param ticket_no The ticket number to check (starting from 0 for the first ticket).
    * @return won A boolean indicating whether the specified ticket has won.   
    */
    function checkIfMyTicketWon(
        uint lottery_no, 
        uint ticket_no
    )   public 
        view
        lotteryControl(lottery_no)
        returns (bool won) {

        LotteryStorage.State storage s = LotteryStorage.getStorage();
        LotteryStructs.Lottery storage lottery = s.lotteries[lottery_no-1];

        require(lottery.state == LotteryStructs.LotteryState.COMPLETED, "Lottery is not COMPLETED state");
        require(ticket_no < s.lotteryTickets[lottery_no].length, "Invalid ticket number");

        LotteryStructs.Ticket storage ticket = s.lotteryTickets[lottery_no][ticket_no];

        // Verify that the caller owns the ticket
        require(ticket.owner == msg.sender, "You do not own this ticket");
        require(ticket.revealed == true , "You did not submitted your random number");

        // Check if ticketNo is in the list of winners for the lottery
        for (uint256 i = 0; i < lottery.lotteryWinners.length;i++) {
            if (lottery.lotteryWinners[i] == ticket_no) {
                return true;
            }
        }
        return false;
    }

    /*
    Checks if a specific ticket owned by a given address has won in a specified lottery.
    @param addr The address of the ticket owner.
    @param lottery_no The ID of the lottery.
    @param ticket_no The ticket number to check (starting from 0 for the first ticket).
    @return won A boolean indicating whether the specified ticket has won.
    */
    function checkIfAddrTicketWon(
        address addr,
        uint lottery_no,
        uint ticket_no
    )   public
        view
        lotteryControl(lottery_no)
        returns (bool won) {

        LotteryStorage.State storage s = LotteryStorage.getStorage();
        LotteryStructs.Lottery storage lottery = s.lotteries[lottery_no-1];

        // Validation
        require(lottery.state == LotteryStructs.LotteryState.COMPLETED, "Lottery not completed");
        require(ticket_no < s.lotteryTickets[lottery_no].length, "Invalid ticket number");

        LotteryStructs.Ticket storage ticket = s.lotteryTickets[lottery_no][ticket_no];
        require(ticket.owner == addr, "Address does not own this ticket");

        require(s.lotteryTickets[lottery_no][ticket_no].revealed == true, "The address was not submitted its random number");

        // Check if ticketNo is in the list of winners for the lottery
        for (uint256 i = 0; i < lottery.lotteryWinners.length;i++) {
            if (lottery.lotteryWinners[i] == ticket_no) {
                if (ticket.owner == addr) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Helper function to check if a ticket index is already a winner.
     * @param winners Array of winner ticket indices.
     * @param ticket_no The ticket index to check.
     * @return isDuplicate Boolean indicating if the ticket index is a duplicate winner.
     */
    function _isDuplicateWinner(uint256[] memory winners, uint256 ticket_no) private pure returns (bool isDuplicate) {
        for (uint256 i = 0; i < winners.length; i++) {
            if (winners[i] == ticket_no) {
                return true;
            }
        }
        return false;
    }
}