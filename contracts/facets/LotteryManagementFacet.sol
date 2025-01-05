// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LotteryStorage.sol";
import "../libraries/LotteryStructs.sol";
import "./AccessControlFacet.sol";

/**
 * LotteryManagementFacet
 * Facet responsible for managing lotteries in a Diamond architecture.
 */
contract LotteryManagementFacet {

    /**
     * Event emitted when lottery is created.
     * @param lottery_no The ID of the lottery.
     * @param unixbeg Time
     * @param nooftickets Number of tickets lottery has.
     */
    event LotteryCreated(uint lottery_no, uint unixbeg, uint nooftickets);

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
     * Creates a new lottery with the given parameters.
     * @param unixbeg The start time of the lottery (in Unix timestamp).
     * @param nooftickets The total number of tickets available for the lottery.
     * @param noofwinners The number of winners to select for the lottery.
     * @param minpercentage The minimum percentage of tickets that must be sold for the lottery to be valid.
     * @param ticketprice The price of each ticket (in the payment token).
     * @param htmlhash The hash of the HTML content related to the lottery.
     * @param url The URL for more details about the lottery.
     */
    function createLottery (
        uint unixbeg,
        uint nooftickets,
        uint noofwinners,
        uint minpercentage,
        uint ticketprice,
        bytes32 htmlhash,
        string memory url
    )   public 
        onlyOwner
        returns (uint lottery_no) {
        // Access storage
        LotteryStorage.State storage s = LotteryStorage.getStorage();

        uint256 currenttime = block.timestamp;

        // Validate inputs
        require(nooftickets > 0, "Number of tickets must be greater than 0");
        require(noofwinners > 0, "Number of winners must be greater than 0");
        require(minpercentage <= 100, "Minimum percentage cannot exceed 100");
        require(ticketprice > 0, "Ticket price must be greater than 0");
        require(unixbeg > currenttime, "Time must be in the future");

        s.currentLotteryNo++; // Increment the current lottery number

        // Create the lottery object
        LotteryStructs.Lottery memory newLottery = LotteryStructs.Lottery({
            unixbeg: unixbeg,
            nooftickets: nooftickets,
            noofwinners: noofwinners,
            minpercentage: minpercentage,
            ticketprice: ticketprice,
            htmlhash: htmlhash,
            url: url,
            revealStartTime: currenttime + ((unixbeg - currenttime) / 2),  // half the time of total
            state: LotteryStructs.LotteryState.PURCHASE,
            numsold: 0,
            numpurchasetxs: 0,
            currentRandom: 0,
            lotteryWinners: new uint[](noofwinners) // Initialize array with winner slots
        });

        // Add the lottery to storage
        s.lotteries[s.currentLotteryNo] = newLottery;

        emit LotteryCreated(s.currentLotteryNo, unixbeg, nooftickets); 

        return s.currentLotteryNo;
    }

       /**
     * Retrieves the essential information about a specific lottery.
     * @param lottery_no The ID of the lottery whose information is being requested
     * @return unixbeg Start time of the lottery (in Unix timestamp)
     * @return nooftickets Total number of tickets in the lottery
     * @return noofwinners Number of winners to be selected
     * @return minpercentage Minimum percentage of tickets to be sold for the lottery to be valid
     * @return ticketprice Price of each ticket (in the NBG Token)
    */
    function getLotteryInfo(uint256 lottery_no)
        public
        view
        lotteryControl(lottery_no)
        returns (
            uint256 unixbeg,
            uint256 nooftickets,
            uint256 noofwinners,
            uint256 minpercentage,
            uint256 ticketprice
        )
    {    
        // Access the lottery info for the specified lottery number
        LotteryStorage.State storage s = LotteryStorage.getStorage();
        LotteryStructs.Lottery storage lottery = s.lotteries[lottery_no-1];

        return (
            lottery.unixbeg,
            lottery.nooftickets,
            lottery.noofwinners,
            lottery.minpercentage,
            lottery.ticketprice
        );
    }

    /**
     * Retrieves the state of a specific lottery.
     * @param lottery_no The ID of the lottery.
     * @return The state of the lottery.
     */
    function getLotteryState(uint256 lottery_no)
        public
        view
        lotteryControl(lottery_no)
        returns (LotteryStructs.LotteryState)
    {          
        LotteryStorage.State storage s = LotteryStorage.getStorage();
        return s.lotteries[lottery_no-1].state;
    }

    /**
    * Updates the states of all lotteries based on current conditions.
    * Transitions include:
    * - PURCHASE ➔ REVEAL if revealStartTime is reached.
    * - REVEAL ➔ COMPLETED if unixbeg is reached and minimum tickets are sold.
    * - Any state ➔ CANCELLED if unixbeg is reached and minimum tickets are not sold.
    */
    function updateLotteryStates()
        public {
        uint256 currentTime = block.timestamp;

        LotteryStorage.State storage s = LotteryStorage.getStorage();

        for (uint256 i = 0; i < s.currentLotteryNo; i++) {

            LotteryStructs.Lottery storage lottery = s.lotteries[i];
            
            if (lottery.state == LotteryStructs.LotteryState.PURCHASE) {
                // Transition to REVEAL if revealStartTime is reached
                if (currentTime >=  lottery.revealStartTime) {
                    lottery.state = LotteryStructs.LotteryState.REVEAL;
                }
            } else if (lottery.state == LotteryStructs.LotteryState.REVEAL) {
                // Transition to COMPLETED if enough tickets sold, else CANCELLED
                if (currentTime >=  lottery.unixbeg) {
                    uint256 minTicketsRequired = (lottery.nooftickets * lottery.minpercentage) / 100;
                    if (lottery.numsold >= minTicketsRequired) {
                        lottery.state = LotteryStructs.LotteryState.COMPLETED;
                    } else {
                        lottery.state = LotteryStructs.LotteryState.CANCELLED;
                    }
                }
            } else if (
                lottery.state == LotteryStructs.LotteryState.PURCHASE ||
                lottery.state == LotteryStructs.LotteryState.REVEAL)
            {
                // Cancel lotteries if end time passed and they haven't transitioned
                if (currentTime >=  lottery.unixbeg) {
                    uint256 minTicketsRequired = (lottery.nooftickets * lottery.minpercentage) / 100;
                    if (lottery.numsold < minTicketsRequired) {
                        lottery.state = LotteryStructs.LotteryState.CANCELLED;
                    }
                }
            }
        }  
    }

    /**
    * View function to get information of a ticket.
    * Allows anyone to view the quantity of tickets purchased in the Ith transaction for a specified lottery
    * @param i Ticket index number (starts with 1 as first)
    * @param lottery_no lottery number which the ticket is in
    * @return sticketno Sold ticket no
    * @return quantity Quantity of tickets sold
    */
    function getIthPurchasedTicketTx(
        uint i, 
        uint lottery_no
    )   public
        view
        lotteryControl(lottery_no)
        returns (uint sticketno, uint quantity) {   

        // Access the lottery info for the specified lottery number
        LotteryStorage.State storage s = LotteryStorage.getStorage();
                
        // Check if the number of ticket is more than total ticket sold
        require(i <= s.lotteryTickets[lottery_no].length);

        // Access the ticket information
        LotteryStructs.Ticket storage ticket = s.lotteryTickets[lottery_no][i];

        return (i, ticket.quantity);
    }

    /**
    * Retrieves the number of purchase Transactions a specific lottery.
    * @param lottery_no Lottery ID which is used to retrieve information about its transactions.
    * @return numpurchasetxs Number of transactions
    */
    function getNumPurchaseTxs(uint lottery_no)
        public
        view
        lotteryControl(lottery_no)
        returns (uint numpurchasetxs) {
        LotteryStorage.State storage s = LotteryStorage.getStorage();
        return s.lotteries[lottery_no-1].numpurchasetxs;
    }

    /*
    * Retrieves the URL and the associated hash (HTML hash) for a given lottery.
    * This function allows users to fetch the URL and the HTML hash linked to a specific lottery.
    * @param lottery_no The ID of the lottery whose URL and HTML hash are being queried.
    *        It corresponds to a specific lottery stored in the `lotteries` mapping.
    * @return htmlhash The bytes32 hash of the HTML content related to the lottery. 
    *         This could represent a hash of a web page or resource related to the lottery.
    * @return url The string URL associated with the lottery.
    *         This could be the link to the lottery's page or additional information about the lottery.
    */
    function getLotteryURL(uint lottery_no)
        public
        view
        lotteryControl(lottery_no)
        returns (bytes32 htmlhash, string memory url) {

        LotteryStorage.State storage s = LotteryStorage.getStorage();
        LotteryStructs.Lottery storage lottery = s.lotteries[lottery_no-1];
        return (lottery.htmlhash, lottery.url);
    }

    /**
    * Retrieves the number of ticket sold for a specific lottery.
    * @param lottery_no Lottery ID which is used to retrieve information about its state and sold tickets
    * @return numsold Number of purchased tickets in that particular lottery
    */
    function getLotterySales(uint lottery_no)
        public
        view
        lotteryControl(lottery_no)
        returns (uint numsold) {
        LotteryStorage.State storage s = LotteryStorage.getStorage();
        return s.lotteries[lottery_no-1].numsold;
    }

}