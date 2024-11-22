// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./LotteryStructs.sol";

//SORU
//Lottery Stage Change Function
/* Ne zaman çağırılacak?
 */

/*
    Custom ERC20 token for the lottery system.
*/
contract TicketToken is ERC20 {
    address public owner; // address of the contract owner

    /*
        Sets up the token with a name and symbol, and assigns the owner.
        Inherits ERC20 constructor for token initialization
    */
    constructor() ERC20("NuBaGo Token", "NBG") {
        owner = msg.sender;
    }

    /*
        // TODO: enough?
        @param to the address to receive the tokens
        @param amount number of tokens to get
    */
    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "Only the owner can mint token");
        _mint(to, amount);
    }
}

/*
    This contract manages lotteries using ERC20 token.
    TODO: Explain more
*/
contract CompanyLotteries {
    using LotteryStructs for *; // Using the LotteryInfo, TicketInfo structs and LotteryState enum

    TicketToken public ticketToken;
    address public owner;
    uint256 public currentLotteryNo;

    mapping(uint256 => LotteryStructs.LotteryInfo) public lotteries; // Mapping of lottery IDs to LotteryInfo
    mapping(uint256 => LotteryStructs.TicketInfo[]) public lotteryTickets; // Mapping of lottery IDs to an array of TicketInfo structs
    //mapping(uint256 => uint256[]) public lotteryWinners; // Mapping from lottery number to an array of winning ticket numbers
    //mapping(uint256 => uint256[]) public randomNumbers; // Mapping from lottery number to an array of random numbers
    // Mapping from user address to their ticket number list for each lottery.
    /*
        addressToTickets = {
        0xABC123...: {    // Address of User A
            1: [100, 101, 102]  // Lottery 1, Tickets 100, 101, 102
        }
    }*/
    mapping(address => mapping(uint256 => uint256[])) public addressToTickets;

    event LotteryCreated(
        uint256 lottery_no,
        uint256 unixbeg,
        uint256 nooftickets
    ); // Track created lotteries
    event TicketPurchased(
        uint256 lottery_no,
        uint256 ticketNo,
        uint256 quantity
    ); // Track purchased tickets
    event RandomNumberRevealed(
        uint256 lottery_no,
        uint256 ticketNo,
        uint256 rnd_number
    ); // Reveals random number
    event RefundWithdrawn(
        uint256 lottery_no,
        address participant,
        uint256 refundAmount
    ); // Refund track if lottery cancelled
    event LotteryStateUpdated(uint256 lottery_no);

    //event WinnerDeclared(uint lotteryNo, uint winningTicketNo);

    /*
        Sets the owner and initializes TicketToken contract.
        @param _ticketTokenAddress address of the deployed TicketToken contract
    */
    constructor(address _ticketTokenAddress) {
        owner = msg.sender;
        ticketToken = TicketToken(_ticketTokenAddress);
    }

    /*
        Modifier to control functions that can be called by the owner only
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    /*
        Creates a new lottery with Lottery Struct
        @param unixbeg End time of the lottery (in Unix timestamp)
        @param noOfTickets Total number of tickets in the lottery
        @param noOfWinners Number of winners to be selected
        @param minPercentage Minimum percentage of tickets to be sold for the lottery to be valid
        @param ticketPrice Price of each ticket (in the NBG Token)
        @returns currentLotteryNo Lottery number of created lottery
    */

function createLottery(
        uint256 unixbeg,
        uint256 nooftickets,
        uint256 noofwinners,
        uint256 minpercentage,
        uint256 ticketprice,
        bytes32 htmlhash,
        string memory url
    ) public onlyOwner returns (uint256 lottery_no) {
        require(noofwinners > 0, "At least one winner required");
        require(minpercentage <= 100, "Min participation cannot exceed 100");
        //time limits
        uint256 currentTime = block.timestamp;
        require(
            unixbeg > currentTime,
            "Lottery end time must be in the future."
        );
        currentLotteryNo++;
        lotteries[currentLotteryNo] = LotteryStructs.LotteryInfo({
            unixbeg: unixbeg, //end time
            nooftickets: nooftickets,
            noofwinners: noofwinners,
            minpercentage: minpercentage,
            ticketprice: ticketprice,
            numsold: 0,
            state: LotteryStructs.LotteryState.PURCHASE,
            numpurchasetxs: 0,
            sticketno: 0,
            htmlhash: htmlhash,
            url: url,
            erctokenaddr: address(ticketToken),
            revealStartTime: currentTime + ((unixbeg - currentTime) / 2), // (half the time of total)
            lotteryWinners: new uint256[](noofwinners),
            randomNumbers: new uint256[](nooftickets)
        });


        emit LotteryCreated(currentLotteryNo, unixbeg, nooftickets);
        return currentLotteryNo;
    }


    /*
        TODO comment
        @param lottery_no Lottery which the ticket will be purchased
        @param quantity Number of tickets to be purchased
        @param hash_rnd_number Hash generated by the user by using their address and random number
        @return sTicketNo
    */
    function buyTicketTx(
        uint256 lottery_no,
        uint256 quantity,
        bytes32 hash_rnd_number
    ) public returns (uint256 sticketno) {
        // Check if the lottery is active, lottery is finished, and are there enough tickets to sold
        require(
            lotteries[lottery_no].state == LotteryStructs.LotteryState.PURCHASE,
            "Lottery is not active"
        );
        require(
            block.timestamp < lotteries[lottery_no].revealStartTime,
            "Lottery sale is done"
        );
        require(
            lotteries[lottery_no].numsold + quantity <=
                lotteries[lottery_no].nooftickets,
            "Not enough tickets available"
        );

        // Calculate total cost
        //uint256 totalCost = quantity * lotteries[lottery_no].ticketprice;
        // ticketToken.transferFrom(msg.sender, owner, totalCost);

        // Construct a ticket with the info provided
        LotteryStructs.TicketInfo memory ticket = LotteryStructs.TicketInfo({
            participant: msg.sender,
            quantity: quantity,
            hash_rnd_number: hash_rnd_number,
            revealed: false
        });

        lotteryTickets[lottery_no].push(ticket);
        sticketno = lotteryTickets[lottery_no].length - 1;

        lotteries[lottery_no].numsold += quantity;
        // Add tickets to user's list in addressToTickets mapping
        for (uint256 i = 0; i < quantity; i++) {
            uint256 Currentticketno = lotteries[lottery_no].sticketno;
            Currentticketno += 1;
            lotteries[lottery_no].sticketno = Currentticketno;
            addressToTickets[msg.sender][lottery_no].push(Currentticketno); // Add consecutive ticket numbers
        }

        //update purchase transactions
        lotteries[currentLotteryNo].numpurchasetxs += 1;

        // Log ticket purchased
        emit TicketPurchased(currentLotteryNo, sticketno, quantity);
    }

    /*
        TODO explanation
    */
    function revealRndNumberTx(
        uint256 lottery_no,
        uint256 sticketno,
        uint256 quantity,
        uint256 rnd_number
    ) public {
        require(
            sticketno < lotteryTickets[lottery_no].length,
            "Ticket does not exist"
        );
        LotteryStructs.TicketInfo storage ticket = lotteryTickets[lottery_no][
            sticketno
        ];
        require(ticket.participant == msg.sender, "Not the ticket owner");
        require(ticket.quantity == quantity, "Quantity mismatch");
        require(!ticket.revealed, "Random number already revealed");

        // Verify that hash of provided rnd_number matches the committed hash
        require(
            ticket.hash_rnd_number == keccak256(abi.encodePacked(rnd_number)),
            "Random number does not match commitment"
        );

        ticket.revealed = true;
        //add random number to list
        lotteries[lottery_no].randomNumbers.push(rnd_number);
        emit RandomNumberRevealed(lottery_no, sticketno, rnd_number);
    }

    // Getter functions
    /*
        View function to get information of a ticket.
        Allows anyone to view the quantity of tickets purchased in the Ith transaction for a specified lottery
        @param i Ticket index number (starts with 1 as first)
        @param lottery_no lottery number which the ticket is in
        @return sTicketNo Sold ticket no
        @return quantity Quantity of tickets sold
    */
    function getIthPurchasedTicketTx(uint256 i, uint256 lottery_no)
        public
        view
        returns (uint256 sticketno, uint256 quantity)
    {
        // Decrement i by 1 to match the array index
        i = i - 1;
        // Check if the number of ticket is more than total ticket sold
        require(i < lotteryTickets[lottery_no].length, "Index out of range");
        // Create a reference to a specific TicketInfo struct stored in the contract’s state
        LotteryStructs.TicketInfo storage ticket = lotteryTickets[lottery_no][
            i
        ];
        return (i, ticket.quantity);
    }

    /*
        Retrieves the essential information about a specific lottery based on its unique lottery ID
        @param unixbeg Start time of the lottery (in Unix timestamp)
        @param noOfTickets Total number of tickets in the lottery
        @param noOfWinners Number of winners to be selected
        @param minPercentage Minimum percentage of tickets to be sold for the lottery to be valid
        @param ticketPrice Price of each ticket (in the NBG Token)
    */
    function getLotteryInfo(uint256 lottery_no)
        public
        view
        returns (
            uint256 unixbeg,
            uint256 nooftickets,
            uint256 noofwinners,
            uint256 minpercentage,
            uint256 ticketprice
        )
    {
        // Access the LotteryInfo struct for the specified lottery number
        LotteryStructs.LotteryInfo storage lottery = lotteries[lottery_no];
        return (
            lottery.unixbeg,
            lottery.nooftickets,
            lottery.noofwinners,
            lottery.minpercentage,
            lottery.ticketprice
        );
    }

    /*
        Retrieves the number of purchase Transactions a specific lottery.
        @param lottery_no Lottery ID which is used to retrieve information about its transactions.
        @return numpurchasetxs Number of transactions
        TODO: Transaction için yeni parametre ekledim, bunu sor.
    */
    function getNumPurchaseTxs(uint256 lottery_no)
        public
        view
        returns (uint256 numpurchasetxs)
    {
        return lotteries[lottery_no].numpurchasetxs;
    }

    /*
        Returns the current lottery number of the contract.
        @param None
        @return currentLotteryNo Current Lottery number in the contract.
    */
    function getCurrentLotteryNo() public view returns (uint256 lottery_no) {
        return currentLotteryNo;
    }

    /*
        TODO explanation
    */
    function withdrawTicketProceeds(uint256 lottery_no) public onlyOwner {
        // Access the lottery information
        LotteryStructs.LotteryInfo storage lottery = lotteries[lottery_no];
        // Ensure the lottery has ended
        require(
            lottery.state == LotteryStructs.LotteryState.COMPLETED,
            "Lottery is not completed"
        );
        // Calculate the total proceeds from ticket sales
        uint256 totalProceeds = lottery.numsold * lottery.ticketprice;
        // Ensure there are proceeds to withdraw
        require(totalProceeds > 0, "No proceeds to withdraw");
        // Transfer the proceeds to the owner
        require(ticketToken.transfer(owner, totalProceeds), "Transfer failed");
    }

    /*
        TODO explanation
    */
    function setPaymentToken(address ercTokenAddr) public onlyOwner {
        require(ercTokenAddr != address(0), "Invalid token address");
        lotteries[currentLotteryNo].erctokenaddr = ercTokenAddr;
    }

    /*
        Retrieves the number of ticket sold for a specific lottery.
        @param lottery_no Lottery ID which is used to retrieve information about its state and sold tickets
        @return soldTickets Number of purchased tickets in that particular lottery
    */
    function getLotterySales(uint256 lottery_no)
        public
        view
        returns (uint256 numsold)
    {
        return lotteries[lottery_no].numsold;
    }

    /*
        Retrieves the adress of the payment token for a specific lottery.
        @param lottery_no Lottery ID which is used to retrieve information about its state and sold tickets
        @return erctokenaddr Adress of the payment token in that particular lottery
        Not: ne yaptığını sor? 
    */
    function getPaymentToken(uint256 lottery_no)
        public
        view
        returns (address erctokenaddr)
    {
        return lotteries[lottery_no].erctokenaddr;
    }

    /* 
        TODO explanation
    */
    function checkIfMyTicketWon(uint256 lottery_no, uint256 ticketNo)
        public
        view
        returns (bool won)
    {
        // Check if ticketNo is in the list of winners for the lottery
        //LotteryStructs.LotteryInfo storage lottery = lotteries[lottery_no];
        for (
            uint256 i = 0;
            i < lotteries[lottery_no].lotteryWinners.length;
            i++
        ) {
            if (lotteries[lottery_no].lotteryWinners[i] == ticketNo) {
                return true;
            }
        }
        return false;
    }

    /*
        Checks if a user specified by their adress has won the lottery with a specific ticket.
        @param lottery_no Lottery ID
        @param addr address of the user
        @param ticket_no Ticket number which the user wants to check. 
        @return won Whether the address has already won or not
    */

    
    function checkIfAddrTicketWon(
        address addr,
        uint256 lottery_no,
        uint256 ticket_no
    ) public view returns (bool won) {
        // Ensure the lottery has ended
        require(
            lotteries[lottery_no].state ==
                LotteryStructs.LotteryState.COMPLETED,
            "Lottery has not ended"
        );

        // Get the list of winning tickets for the given lottery
        uint256[] memory winningTickets = lotteries[lottery_no].lotteryWinners;
        uint256[] memory userTickets = addressToTickets[addr][lottery_no];

        // Check if the ticket exists in the user's list of tickets
        bool ticketExists = false;
        for (uint256 i = 0; i < userTickets.length; i++) {
            if (userTickets[i] == ticket_no) {
                ticketExists = true;
                break;
            }
        }

        // If the ticket exists, check if it is a winning ticket
        if (ticketExists) {
            for (uint256 i = 0; i < winningTickets.length; i++) {
                if (winningTickets[i] == ticket_no) {
                    return true; // Ticket is a winner
                }
            }
        }
        return false; // Ticket is not a winner
    }

    /*
        TODO explanation
    */
    function getIthWinningTicket(uint256 lottery_no, uint256 i)
        public
        view
        returns (uint256 ticketno)
    {
        // Access the winning tickets array for the specified lottery
        uint256[] storage winningTickets = lotteries[lottery_no].lotteryWinners;
        // Ensure the index `i` is within bounds
        require(i < winningTickets.length, "Index out of range");
        // Retrieve the winning ticket at the specified index
        ticketno = winningTickets[i];
        return ticketno;
    }

    /*
    Allows users to withdraw a refund for a specific ticket if the lottery was canceled.
    @param lottery_no The ID of the lottery.
    @param sticketNo The starting ticket number of the purchased batch to refund.
    Emits a RefundWithdrawn event upon successful refund.
*/
    
    function withdrawTicketRefund(uint256 lottery_no, uint256 sticketNo)
        public
    {
        // Retrieve the lottery information
        LotteryStructs.LotteryInfo storage lottery = lotteries[lottery_no];
        // Ensure the lottery is in a canceled state
        require(
            lottery.state == LotteryStructs.LotteryState.CANCELLED,
            "Lottery is not canceled"
        );

        // Ensure the refund has not already been withdrawn
        // require(!lottery.refunds[msg.sender], "Refund already withdrawn");

        // Retrieve the list of ticket numbers owned by the caller for this lottery
        uint256[] storage userTickets = addressToTickets[msg.sender][
            lottery_no
        ];
        bool ticketFound = false;

        // Check if the caller owns the ticket number
        for (uint256 i = 0; i < userTickets.length; i++) {
            if (userTickets[i] == sticketNo) {
                ticketFound = true;
                // Remove the ticket from the user's list (optional but recommended for cleanup)
                userTickets[i] = userTickets[userTickets.length - 1];
                userTickets.pop();
                break;
            }
        }
        require(ticketFound, "You do not own this ticket");
        // Calculate the refund amount
        uint256 refundAmount = lottery.ticketprice;

        // Mark the refund as withdrawn
        //lottery.refunds[msg.sender] = true;

        // Transfer the refund amount to the caller
        require(
            ticketToken.transfer(msg.sender, refundAmount),
            "Refund transfer failed"
        );

        // Emit a refund event
        emit RefundWithdrawn(lottery_no, msg.sender, refundAmount);
    }

    /*
        TODO explanation
    */
    function getLotteryURL(uint256 lottery_no)
        public
        view
        returns (bytes32 htmlhash, string memory url)
    {
        LotteryStructs.LotteryInfo storage lottery = lotteries[lottery_no];
        return (lottery.htmlhash, lottery.url);
    }

    /*
        Calculates who won a specific lottery by XOR'ing random numbers.
        @param lottery_no Lottery ID
        @return winner_ticket_no Winner of that lottery
    */
    function determineWinners(uint256 lottery_no)
        external
        view
        returns (uint256[] memory winner_ticket_numbers)
    {
        require(
            lotteries[lottery_no].state ==
                LotteryStructs.LotteryState.COMPLETED,
            "Lottery is not completed"
        );

        uint256 finalRandomNumber = 0;

        // XOR all revealed numbers to calculate the final random number
        for (
            uint256 i = 0;
            i < lotteries[lottery_no].randomNumbers.length;
            i++
        ) {
            uint256 userRandomNumber = lotteries[lottery_no].randomNumbers[i];
            finalRandomNumber ^= userRandomNumber;
        }

        uint256 numOfWinners = lotteries[lottery_no].noofwinners;
        require(
            numOfWinners <= lotteries[lottery_no].randomNumbers.length,
            "Number of winners exceeds participants"
        );

        // Array to store the winning ticket numbers
        winner_ticket_numbers = new uint256[](numOfWinners);
        uint256[] memory selectedIndexes = new uint256[](numOfWinners);
        uint256 participants = lotteries[lottery_no].randomNumbers.length;

        // Select unique winners
        for (uint256 i = 0; i < numOfWinners; i++) {
            uint256 winnerIndex = uint256(
                keccak256(abi.encode(finalRandomNumber, i))
            ) % participants;

            // Ensure unique winner
            while (isIndexSelected(winnerIndex, selectedIndexes, i)) {
                winnerIndex = (winnerIndex + 1) % participants;
            }

            winner_ticket_numbers[i] = lotteries[lottery_no].randomNumbers[
                winnerIndex
            ];
            selectedIndexes[i] = winnerIndex;
        }

        return winner_ticket_numbers;
    }

    // Helper function to check if an index is already selected
    function isIndexSelected(
        uint256 index,
        uint256[] memory selectedIndexes,
        uint256 count
    ) private pure returns (bool) {
        for (uint256 i = 0; i < count; i++) {
            if (selectedIndexes[i] == index) {
                return true;
            }
        }
        return false;
    }

    //Lottery Stage Change Function
    /* Ne zaman çağırılacak?
     */
    function updateLotteryState(uint256 lottery_no) public onlyOwner {
        // Check that the lottery exists
        require(lotteries[lottery_no].unixbeg != 0, "Lottery does not exist");
        // Ensure valid state transitions PURCHASE -> REVEAL
        if (
            (lotteries[lottery_no].state ==
                LotteryStructs.LotteryState.PURCHASE) &&
            (block.timestamp >= lotteries[lottery_no].revealStartTime)
        ) {
            lotteries[lottery_no].state == LotteryStructs.LotteryState.REVEAL;
        }
        // Ensure valid state transitions REVEAL -> COMPLETED
        if (
            (lotteries[lottery_no].state ==
                LotteryStructs.LotteryState.REVEAL) &&
            (block.timestamp >= lotteries[lottery_no].unixbeg)
        ) {
            lotteries[lottery_no].state ==
                LotteryStructs.LotteryState.COMPLETED;
        }
        // Ensure valid state transitions CANCELLATION
        uint256 soldpercentage = (lotteries[lottery_no].numsold /
            lotteries[lottery_no].nooftickets) * 100;
        if (
            (lotteries[lottery_no].minpercentage > soldpercentage) &&
            (block.timestamp >= lotteries[lottery_no].revealStartTime)
        ) {
            lotteries[lottery_no].state ==
                LotteryStructs.LotteryState.CANCELLED;
        }

        // Emit an event to track the state change
        emit LotteryStateUpdated(lottery_no);
    }

    /*
    createLottery - MGE - implemented
    buyTicketTx - MGE - implementing (total cost)
    revealRndNumberTx - Nurhan - implemented
    getNumPurchaseTxs - Başak - implemented
    getIthPurchasedTicketTx - MGE - implemented
    checkIfMyTicketWon - Nurhan - implemented
    checkIfAddrTicketWon - Başak - implemented
    getIthWinningTicket-  NURHAN - implemented
    withdrawTicketRefund - Nurhan - implemented
    getCurrentLotteryNo - Başak - implemented
    withdrawTicketProceeds-  NURHAN - implemented
    setPaymentToken - Nurhan - implemented
    getPaymentToken - Başak - implemented
    getLotteryInfo - MGE - implemented
    getLotteryURL - Nurhan - implemented
    getLotterySales - Başak - implemented
    determineWinner (Random Number selection) - Başak - impelemented
    Lottery State Functions - Başak - implementing 
    -States 4 of 5 (inaktife gerek yok)
    : Purchase (in start) -> DONE 
    - Reveal (before number submissions), 
    - Completed (after reveal) , 
    - Cancelled (not enough tickets)
    Lottery state satılan ticket adedine göre CANCELLED olabilir. Bunu otomatik kontrol eden/update eden bir fonksiyon olmalı.
    */
}
