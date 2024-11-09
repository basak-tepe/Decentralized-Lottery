// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TicketToken is ERC20 {
    address public owner;

    constructor() ERC20("LotteryTicket", "LTK") {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "Only the owner can mint tickets");
        _mint(to, amount);
    }
}

contract CompanyLottery {
    struct Lottery {
        uint unixbeg;
        uint nooftickets;
        uint noofwinners;
        uint minpercentage;
        uint ticketprice;
        bytes32 htmlhash;
        string url;
        uint soldTickets;
        bool isActive;
        address paymentToken;
    }

    struct Ticket {
        address participant;
        uint quantity;
        bytes32 hash_rnd_number; // Committed hash of random number
        bool revealed;
    }

    TicketToken public ticketToken;
    address public owner;
    uint public currentLotteryNo;
    mapping(uint => Lottery) public lotteries;
    mapping(uint => Ticket[]) public lotteryTickets; // List of tickets per lottery
    mapping(uint => mapping(uint => uint)) public ticketPurchaseQuantities;

    event LotteryCreated(uint lotteryNo, uint unixbeg, uint nooftickets);
    event TicketPurchased(uint lotteryNo, uint ticketNo, uint quantity);
    event RandomNumberRevealed(uint lotteryNo, uint ticketNo, uint rnd_number);
    event WinnerDeclared(uint lotteryNo, uint winningTicketNo);

    constructor(address _ticketTokenAddress) {
        owner = msg.sender;
        ticketToken = TicketToken(_ticketTokenAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function createLottery(
        uint unixbeg,
        uint nooftickets,
        uint noofwinners,
        uint minpercentage,
        uint ticketprice,
        bytes32 htmlhash,
        string memory url
    ) public onlyOwner returns (uint lotteryNo) {
        require(noofwinners > 0, "At least one winner required");
        require(minpercentage <= 100, "Min participation cannot exceed 100");

        currentLotteryNo++;
        lotteries[currentLotteryNo] = Lottery({
            unixbeg: unixbeg,
            nooftickets: nooftickets,
            noofwinners: noofwinners,
            minpercentage: minpercentage,
            ticketprice: ticketprice,
            htmlhash: htmlhash,
            url: url,
            soldTickets: 0,
            isActive: true,
            paymentToken: address(ticketToken)
        });

        emit LotteryCreated(currentLotteryNo, unixbeg, nooftickets);
        return currentLotteryNo;
    }

    function buyTicketTx(uint quantity, bytes32 hash_rnd_number) public returns (uint sticketno) {
        require(lotteries[currentLotteryNo].isActive, "Lottery is not active");
        require(block.timestamp < lotteries[currentLotteryNo].unixbeg, "Lottery has ended");
        require(lotteries[currentLotteryNo].soldTickets + quantity <= lotteries[currentLotteryNo].nooftickets, "Not enough tickets available");

        uint totalCost = quantity * lotteries[currentLotteryNo].ticketprice;
        ticketToken.transferFrom(msg.sender, owner, totalCost);

        Ticket memory ticket = Ticket({
            participant: msg.sender,
            quantity: quantity,
            hash_rnd_number: hash_rnd_number,
            revealed: false
        });

        lotteryTickets[currentLotteryNo].push(ticket);
        sticketno = lotteryTickets[currentLotteryNo].length - 1;

        lotteries[currentLotteryNo].soldTickets += quantity;
        emit TicketPurchased(currentLotteryNo, sticketno, quantity);
    }

    function revealRndNumberTx(uint sticketno, uint quantity, uint rnd_number) public {
        require(sticketno < lotteryTickets[currentLotteryNo].length, "Ticket does not exist");
        Ticket storage ticket = lotteryTickets[currentLotteryNo][sticketno];
        require(ticket.participant == msg.sender, "Not the ticket owner");
        require(ticket.quantity == quantity, "Quantity mismatch");
        require(!ticket.revealed, "Random number already revealed");
        
        // Verify that hash of provided rnd_number matches the committed hash
        require(ticket.hash_rnd_number == keccak256(abi.encodePacked(rnd_number)), "Random number does not match commitment");

        ticket.revealed = true;
        emit RandomNumberRevealed(currentLotteryNo, sticketno, rnd_number);
    }

    function getNumPurchaseTxs(uint lotteryNo) public view returns (uint numpurchasetxs) {
        return lotteryTickets[lotteryNo].length;
    }

    function getIthPurchasedTicketTx(uint i, uint lotteryNo) public view returns (uint sticketno, uint quantity, address participant) {
        require(i < lotteryTickets[lotteryNo].length, "Index out of range");
        Ticket storage ticket = lotteryTickets[lotteryNo][i];
        return (i, ticket.quantity, ticket.participant);
    }

    function checkIfMyTicketWon(uint lotteryNo, uint ticketNo) public view returns (bool won) {
        // Check if ticketNo is in the list of winners for the lottery
    }

    function checkIfAddrTicketWon(address addr, uint lotteryNo, uint ticketNo) public view returns (bool won) {
        // Check if addr's ticket won in lotteryNo
    }

    function getIthWinningTicket(uint lotteryNo, uint i) public view returns (uint ticketNo) {
        // Return the i-th winning ticket
    }

    function withdrawTicketRefund(uint lotteryNo, uint sticketNo) public {
        // Refund logic if the lottery was canceled
    }

    function getCurrentLotteryNo() public view returns (uint lotteryNo) {
        return currentLotteryNo;
    }

    function withdrawTicketProceeds(uint lotteryNo) public onlyOwner {
        // Withdraw proceeds to the lottery owner
    }

    function setPaymentToken(address ercTokenAddr) public onlyOwner {
        require(ercTokenAddr != address(0), "Invalid token address");
        lotteries[currentLotteryNo].paymentToken = ercTokenAddr;
    }

    function getPaymentToken(uint lotteryNo) public view returns (address ercTokenAddr) {
        return lotteries[lotteryNo].paymentToken;
    }

    function getLotteryInfo(uint lotteryNo) public view returns (
        uint unixbeg,
        uint nooftickets,
        uint noofwinners,
        uint minpercentage,
        uint ticketprice
    ) {
        Lottery storage lottery = lotteries[lotteryNo];
        return (lottery.unixbeg, lottery.nooftickets, lottery.noofwinners, lottery.minpercentage, lottery.ticketprice);
    }

    function getLotteryURL(uint lotteryNo) public view returns (bytes32 htmlhash, string memory url) {
        Lottery storage lottery = lotteries[lotteryNo];
        return (lottery.htmlhash, lottery.url);
    }

    function getLotterySales(uint lotteryNo) public view returns (uint numsold) {
        return lotteries[lotteryNo].soldTickets;
    }
}
