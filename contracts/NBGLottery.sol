// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./LotteryStructs.sol";

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
        require(msg.sender == owner, "Only the owner can mint tickets");
        _mint(to, amount);
    }
}

/*
    This contract manages lotteries using ERC20 token.
    TODO: Explain more
*/
contract NBGLottery {

    using LotteryStructs for *; // Using the LotteryInfo, TicketInfo structs and LotteryState enum

    TicketToken public ticketToken;
    address public owner;
    uint32 public currentLotteryNo;

    mapping(uint32 => LotteryStructs.LotteryInfo) public lotteries; // Mapping of lottery IDs to LotteryInfo

    // TODO tek bir lottery olacağı için map yerine array kullanılabilir ??
    mapping(uint => LotteryStructs.TicketInfo[]) public lotteryTickets; // Mapping of lottery IDs to an array of TicketInfo structs

    event LotteryCreated(uint lotteryNo, uint unixbeg, uint nooftickets); // Track created lotteries
    event TicketPurchased(uint lotteryNo, uint ticketNo, uint8 quantity); // Track purchased tickets

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
        @param unixbeg Start time of the lottery (in Unix timestamp)
        @param noOfTickets Total number of tickets in the lottery
        @param noOfWinners Number of winners to be selected
        @param minPercentage Minimum percentage of tickets to be sold for the lottery to be valid
        @param ticketPrice Price of each ticket (in the NBG Token)
        @returns currentLotteryNo Lottery number of created lottery
    */
    function createLottery(
        uint unixbeg,
        uint32 noOfTickets,
        uint noOfWinners,
        uint16 minPercentage,
        uint ticketPrice
        //bytes32 htmlhash
        //string memory url
    ) public onlyOwner returns (uint lotteryNo) {
        require(noOfWinners > 0, "At least one winner required");
        //require(minpercentage <= 100, "Min participation cannot exceed 100");

        currentLotteryNo++;
        lotteries[currentLotteryNo] = LotteryStructs.LotteryInfo({
            unixbeg: unixbeg,
            noOfTickets: noOfTickets,
            noOfWinners: noOfWinners,
            minPercentage: minPercentage,
            ticketPrice: ticketPrice,
            //htmlhash: htmlhash,
            //url: url,
            soldTickets: 0,
            state: LotteryStructs.LotteryState.ACTIVE,
            paymentToken: address(ticketToken)
        });

        emit LotteryCreated(currentLotteryNo, unixbeg, noOfTickets);
        return currentLotteryNo;
    }

    /*
        TODO comment
        @param quantity Number of tickets to be purchased
        @param hash_rnd_number Hash generated by the user by using their address and random number
        @return sTicketNo
    */
    function buyTicketTx(uint8 quantity, bytes32 hash_rnd_number) public returns(uint sTicketNo) {
        
        // Check if the lottery is active, lottery is finished, and are there enough tickets to sold
        require(lotteries[currentLotteryNo].state == LotteryStructs.LotteryState.ACTIVE, "Lottery is not active");
        require(block.timestamp < lotteries[currentLotteryNo].unixbeg, "Lottery has ended");
        require(lotteries[currentLotteryNo].soldTickets + quantity <= lotteries[currentLotteryNo].noOfTickets, "Not enough tickets available");

        // Calculate total cost
        uint totalCost = quantity * lotteries[currentLotteryNo].ticketPrice;
        // ticketToken.transferFrom(msg.sender, owner, totalCost);

        // Construct a ticket with the info provided
        LotteryStructs.TicketInfo memory ticket = LotteryStructs.TicketInfo({
            participant: msg.sender,
            quantity: quantity,
            hash_rnd_number: hash_rnd_number,
            revealed: false
        });

        lotteryTickets[currentLotteryNo].push(ticket);
        sTicketNo = lotteryTickets[currentLotteryNo].length - 1;

        lotteries[currentLotteryNo].soldTickets += quantity;

        // Log ticket purchased
        emit TicketPurchased(currentLotteryNo, sTicketNo, quantity);
    }

    // Getter functions
    /*
        View function to get information of a ticket.
        Allows anyone to view the quantity of tickets purchased in the Ith transaction for a specified lottery
        @param i Ticket index number (starts with 1 as first)
        @param lotteryNo lottery number which the ticket is in
        @return sTicketNo Sold ticket no
        @return quantity Quantity of tickets sold
    */
    function getIthPurchasedTicketTx(uint32 i, uint32 lotteryNo) public view returns (uint32 sTicketNo, uint8 quantity) {
        // Decrement i by 1 to match the array index
        i = i-1;
        // Check if the number of ticket is more than total ticket sold
        require(i < lotteryTickets[lotteryNo].length, "Index out of range");
        // Create a reference to a specific TicketInfo struct stored in the contract’s state
        LotteryStructs.TicketInfo storage ticket = lotteryTickets[lotteryNo][i];
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
    function getLotteryInfo(uint32 lotteryNo) public view returns (
        uint unixbeg,
        uint noOfTickets,
        uint noOfWinners,
        uint minPercentage,
        uint ticketPrice
    ) {
        // Access the LotteryInfo struct for the specified lottery number
        LotteryStructs.LotteryInfo storage lottery = lotteries[lotteryNo];
        return (lottery.unixbeg, lottery.noOfTickets, lottery.noOfWinners, lottery.minPercentage, lottery.ticketPrice);
    }

    /*
    createLottery - MGE - implementing
    buyTicketTx - MGE - implementing
    function revealRndNumberTx(uint sticketno, quantity, uint rnd_number) public
    function getNumPurchaseTxs(uint lottery_no) public view returns(uint numpurchasetxs)
    getIthPurchasedTicketTx - MGE - implementing
    function checkIfMyTicketWon(uint lottery_no, uint ticket_no) public view returns (bool won)
    function checkIfAddrTicketWon(address addr, uint lottery_no, uint ticket_no) public view returns (bool won)
     function getIthWinningTicket(uint lottery_no,uint i) public view returns (uint ticketno)
    function withdrawTicketRefund(uint lottery_no, uint sticket_no) public
    function getCurrentLotteryNo() public view returns (uint lottery_no)
     function withdrawTicketProceeds(uint lottery_no) public onlyOwner
    function setPaymentToken(address erctokenaddr) public onlyOwner
    function getPaymentToken(uint lottery_no) public returns (address erctokenaddr)
     getLotteryInfo - MGE - implementing
    function getLotteryURL(uint lottery_no) public returns(bytes32 htmlhash, string url)
     function getLotterySales(uint lottery_no) public (uint numsold)
    */

}