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
    uint32 public currentLotteryNo;

    mapping(uint => LotteryStructs.LotteryInfo) public lotteries; // Mapping of lottery IDs to LotteryInfo
    mapping(uint => LotteryStructs.TicketInfo[]) public lotteryTickets; // Mapping of lottery IDs to an array of TicketInfo structs
    mapping(uint => uint[]) public lotteryWinners; // Mapping from lottery number to an array of winning ticket numbers
    mapping(uint => uint[]) public randomNumbers; // Mapping from lottery number to an array of random numbers
    // Mapping from user address to their ticket number list for each lottery.
    /*
        addressToTickets = {
        0xABC123...: {    // Address of User A
            1: [100, 101, 102]  // Lottery 1, Tickets 100, 101, 102
        }
    }*/
    mapping(address => mapping(uint => uint[])) public addressToTickets;

    event LotteryCreated(uint lottery_no, uint unixbeg, uint nooftickets); // Track created lotteries
    event TicketPurchased(uint lottery_no, uint ticketNo, uint8 quantity); // Track purchased tickets
    event RandomNumberRevealed(uint lottery_no, uint ticketNo, uint rnd_number); // Reveals random number
    event RefundWithdrawn(uint lottery_no, address participant, uint refundAmount); // Refund track if lottery cancelled
    event LotteryStateUpdated(uint lottery_no);
    
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
        uint unixbeg,
        uint nooftickets,
        uint noofwinners,
        uint minpercentage,
        uint ticketprice,
        bytes32 htmlhash,
        string memory url
    ) public onlyOwner returns (uint lottery_no) {
        require(noofwinners > 0, "At least one winner required");
        require(minpercentage <= 100, "Min participation cannot exceed 100");
        //time limits
        uint currentTime = block.timestamp;
        require(unixbeg > currentTime, "Lottery end time must be in the future.");
        currentLotteryNo++;
        lotteries[currentLotteryNo] = LotteryStructs.LotteryInfo({
            unixbeg: unixbeg, //end time
            nooftickets: nooftickets,
            noofwinners: noofwinners,
            minpercentage: minpercentage,
            ticketprice: ticketprice,
            htmlhash: htmlhash,
            sticketno: 0,
            url: url,
            numsold: 0,
            numpurchasetxs:0,
            state: LotteryStructs.LotteryState.PURCHASE,
            erctokenaddr: address(ticketToken),
            revealStartTime: currentTime + ((unixbeg - currentTime)/ 2)// (half the time of total)
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
    function buyTicketTx(uint lottery_no, uint8 quantity, bytes32 hash_rnd_number) public returns(uint sticketno) {
        
        // Check if the lottery is active, lottery is finished, and are there enough tickets to sold
        require(lotteries[lottery_no].state == LotteryStructs.LotteryState.PURCHASE, "Lottery is not active");
        require(block.timestamp > lotteries[lottery_no].unixbeg, "Lottery has ended");
        require(lotteries[lottery_no].numsold + quantity <= lotteries[lottery_no].nooftickets, "Not enough tickets available");

        // Calculate total cost
        uint totalCost = quantity * lotteries[lottery_no].ticketprice;
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
        for (uint8 i = 0; i < quantity; i++) {
            uint Currentticketno = lotteries[lottery_no].sticketno;
            Currentticketno +=1;
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
    function revealRndNumberTx(uint lottery_no, uint sticketno, uint quantity, uint rnd_number) public {
        require(sticketno < lotteryTickets[lottery_no].length, "Ticket does not exist");
        LotteryStructs.TicketInfo storage ticket = lotteryTickets[lottery_no][sticketno];
        require(ticket.participant == msg.sender, "Not the ticket owner");
        require(ticket.quantity == quantity, "Quantity mismatch");
        require(!ticket.revealed, "Random number already revealed");
        
        // Verify that hash of provided rnd_number matches the committed hash
        require(ticket.hash_rnd_number == keccak256(abi.encodePacked(rnd_number)), "Random number does not match commitment");

        ticket.revealed = true;
        //add random number to list
        randomNumbers[lottery_no].push(rnd_number);
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
    function getIthPurchasedTicketTx(uint i, uint lottery_no) public view returns (uint sticketno, uint8 quantity) {
        // Decrement i by 1 to match the array index
        i = i-1;
        // Check if the number of ticket is more than total ticket sold
        require(i < lotteryTickets[lottery_no].length, "Index out of range");
        // Create a reference to a specific TicketInfo struct stored in the contract’s state
        LotteryStructs.TicketInfo storage ticket = lotteryTickets[lottery_no][i];
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
    function getLotteryInfo(uint32 lottery_no) public view returns (
        uint unixbeg,
        uint nooftickets,
        uint noofwinners,
        uint minpercentage,
        uint ticketprice
    ) {
        // Access the LotteryInfo struct for the specified lottery number
        LotteryStructs.LotteryInfo storage lottery = lotteries[lottery_no];
        return (lottery.unixbeg, lottery.nooftickets, lottery.noofwinners, lottery.minpercentage, lottery.ticketprice);
    }

    /*
        Retrieves the number of purchase Transactions a specific lottery.
        @param lottery_no Lottery ID which is used to retrieve information about its transactions.
        @return numpurchasetxs Number of transactions
        TODO: Transaction için yeni parametre ekledim, bunu sor.
    */
    function getNumPurchaseTxs(uint lottery_no) public view returns (uint numpurchasetxs){
       return lotteries[lottery_no].numpurchasetxs;
    }

     /*
        Returns the current lottery number of the contract.
        @param None
        @return currentLotteryNo Current Lottery number in the contract.
    */
     function getCurrentLotteryNo() public view returns (uint32 lottery_no) {
        return currentLotteryNo;
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
    function getLotterySales(uint lottery_no) public view returns (uint numsold) {
        return lotteries[lottery_no].numsold;
    }

     /*
        Retrieves the adress of the payment token for a specific lottery.
        @param lottery_no Lottery ID which is used to retrieve information about its state and sold tickets
        @return erctokenaddr Adress of the payment token in that particular lottery
        Not: ne yaptığını sor? 
    */
    function getPaymentToken(uint lottery_no) public view returns (address erctokenaddr){
        return lotteries[lottery_no].erctokenaddr;
    }

    /* 
        TODO explanation
    */
    function checkIfMyTicketWon(uint lottery_no, uint ticketNo) public view returns (bool won) {
        // Check if ticketNo is in the list of winners for the lottery
        //LotteryStructs.LotteryInfo storage lottery = lotteries[lottery_no];
        for (uint i = 0; i < lotteryWinners[lottery_no].length; i++) {
            if (lotteryWinners[lottery_no][i] == ticketNo) {
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
    function checkIfAddrTicketWon(address addr, uint lottery_no, uint ticket_no)
        public view returns (bool won){
        // Ensure the lottery has ended
        require(lotteries[lottery_no].state == LotteryStructs.LotteryState.COMPLETED, "Lottery has not ended");

        // Get the list of winning tickets for the given lottery
        uint[] memory winningTickets = lotteryWinners[lottery_no];
        uint[] memory userTickets = addressToTickets[addr][lottery_no];

        // Check if the ticket exists in the user's list of tickets
        bool ticketExists = false;
        for (uint i = 0; i < userTickets.length; i++) {
            if (userTickets[i] == ticket_no) {
                ticketExists = true;
                break;
            }
        }

        // If the ticket exists, check if it is a winning ticket
        if (ticketExists) {
            for (uint i = 0; i < winningTickets.length; i++) {
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
    function withdrawTicketRefund(uint lottery_no, uint sticketNo) public {
        // Refund logic if the lottery was canceled
        LotteryStructs.LotteryInfo storage lottery = lotteries[lottery_no];
        require(lottery.state == LotteryStructs.LotteryState.CANCELLED, "Lottery is not canceled");
        /*
        // TODO fix
        //require(lottery.ticketOwners[sticketNo] == msg.sender, "You are not the owner of this ticket"); 
        //require(addressToTickets[msg.sender][lottery_no] == msg.sender, "You are not the owner of this ticket");
        //require(lottery.refunds[msg.sender] == 0, "Refund already withdrawn");
        uint refundAmount = lottery.ticketPrice;
        lottery.refunds[msg.sender] = refundAmount;
        IERC20 paymentToken = IERC20(lottery.paymentToken);
        require(paymentToken.transfer(msg.sender, refundAmount), "Refund transfer failed");
        */
        uint refundAmount = 0;
        emit RefundWithdrawn(lottery_no, msg.sender, refundAmount);
    }

    /*
        TODO explanation
    */
    function getLotteryURL(uint lottery_no) public view returns (bytes32 htmlhash, string memory url) {
        LotteryStructs.LotteryInfo storage lottery = lotteries[lottery_no];
        return (lottery.htmlhash, lottery.url);
    }


    /*
        Calculates who won a specific lottery by XOR'ing random numbers.
        @param lottery_no Lottery ID
        @return winner_ticket_no Winner of that lottery
    */
    function determineWinner(uint lottery_no) external view returns (uint winner_ticket_no) {
        require(lotteries[lottery_no].state == LotteryStructs.LotteryState.COMPLETED, "Lottery is not completed");
        uint256 finalRandomNumber = 0;

        // XOR all revealed numbers
        for (uint256 i = 0; i < randomNumbers[lottery_no].length; i++) {
            uint256 userRandomNumber = randomNumbers[lottery_no][i];
            finalRandomNumber ^= userRandomNumber;
        }

        // Determine winner based on final random number
        uint256 winnerIndex = finalRandomNumber % randomNumbers[lottery_no].length;
        winner_ticket_no = randomNumbers[lottery_no][winnerIndex];
        return winner_ticket_no;
    }
   
    //Lottery Stage Change Function
    /* Ne zaman çağırılacak?
    */
    function updateLotteryState(uint lottery_no) public onlyOwner {
        // Check that the lottery exists
        require(lotteries[lottery_no].unixbeg != 0, "Lottery does not exist");
        // Ensure valid state transitions PURCHASE -> REVEAL
        if ((lotteries[lottery_no].state == LotteryStructs.LotteryState.PURCHASE) && (block.timestamp >= lotteries[lottery_no].revealStartTime)) {
            lotteries[lottery_no].state ==  LotteryStructs.LotteryState.REVEAL;
        }
            // Ensure valid state transitions REVEAL -> COMPLETED
        if ((lotteries[lottery_no].state == LotteryStructs.LotteryState.REVEAL) && (block.timestamp >= lotteries[lottery_no].unixbeg)) {
            lotteries[lottery_no].state ==  LotteryStructs.LotteryState.COMPLETED;
        }
        // Ensure valid state transitions CANCELLATION
        uint soldpercentage = (lotteries[lottery_no].numsold / lotteries[lottery_no].nooftickets)*100;
        if ((lotteries[lottery_no].minpercentage > soldpercentage) && (block.timestamp >= lotteries[lottery_no].revealStartTime)) {
            lotteries[lottery_no].state ==  LotteryStructs.LotteryState.CANCELLED;
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
        function getIthWinningTicket(uint lottery_no,uint i) public view returns (uint ticketno)    NURHAN
    withdrawTicketRefund - Nurhan - implemented
    getCurrentLotteryNo - Başak - implemented
        function withdrawTicketProceeds(uint lottery_no) public onlyOwner   NURHAN
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