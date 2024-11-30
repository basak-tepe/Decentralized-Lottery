// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "remix_tests.sol"; // Importing Remix tests
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../contracts/CompanyLotteries.sol"; // Import your contract file here
import "../contracts/LotteryStructs.sol";  // Import LotteryStructs.sol

contract TestCompanyLottery {
    TicketToken public ticketToken;
    CompanyLotteries public lottery;
    address public owner;
    address public participant;
    uint createdLotteryId;
    uint256[] public lotteryWinners;

    function beforeEach() public {
        // Initialize the contract before all tests
        ticketToken = new TicketToken();
        lottery = new CompanyLotteries(address(ticketToken));
        owner = address(this); // Use the contract owner as a participant
        participant = address(0x123); // Random address for the test participant
    }

    // Test for creating a lottery
    function testCreateLottery() public {
        uint unixEndTime = block.timestamp + 36000; // 10 hours from now
        uint nooftickets = 100;
        uint noofwinners = 5;
        uint minpercentage = 50;
        uint ticketprice = 2;

        uint lotteryId = lottery.createLottery(
            unixEndTime,
            nooftickets,
            noofwinners,
            minpercentage,
            ticketprice,
            keccak256(abi.encodePacked("hash")), // Hash
            "http://example.com" // URL
        );
        createdLotteryId = lotteryId;
        
        // Test that the lottery was created successfully
        Assert.equal(lotteryId, 1, "Lottery should be created with ID 1");

        Assert.ok(lotteryId > 0, "Lottery creation failed");

        // Check the lottery info
        (uint unixStart, uint numTickets, uint numWinners, uint minPercent, uint price) = lottery.getLotteryInfo(lotteryId);
        Assert.equal(numTickets, nooftickets, "Number of tickets should match");
        Assert.equal(numWinners, noofwinners, "Number of winners should match");
        Assert.equal(minPercent, minpercentage, "Minimum participation percentage should match");
        Assert.equal(price, ticketprice, "Ticket price should match");
    }

    // Test for purchasing a ticket
    /*function testBuyTicket() public {
        uint lotteryNo = 1;
        uint quantity = 1;
        bytes32 hash_rnd_number = bytes32("randomhash");

        // Mint tokens to the participant
        ticketToken.mint(participant, 1 ether);  // Mint 1 token for the participant
        ticketToken.approve(address(lottery), 1 ether);

        // Purchase the ticket
        uint ticketNo = lottery.buyTicketTx(quantity, hash_rnd_number);
        
        // Check that the ticket was purchased
        (uint ticketNo2, uint ticketQuantity, address ticketParticipant) = lottery.getIthPurchasedTicketTx(ticketNo, lotteryNo);
        Assert.equal(ticketQuantity, quantity, "Ticket quantity should match");
        Assert.equal(ticketParticipant, participant, "Ticket participant should match");
    }*/

    // Test for revealing the random number
    /*function testRevealRndNumber() public {
        uint lotteryNo = 1;
        uint ticketNo = 0;
        uint quantity = 1;
        uint rnd_number = 12345;

        // Mint tokens and purchase ticket
        ticketToken.mint(participant, 1 ether);
        ticketToken.approve(address(lottery), 1 ether);
        lottery.buyTicketTx(quantity, bytes32("randomhash"));

        // Reveal random number
        lottery.revealRndNumberTx(ticketNo, quantity, rnd_number);

        // Check that the random number was revealed
        (bool revealed, uint revealedNumber) = lottery.getTicketRandomNumber(ticketNo);
        Assert.equal(revealed, true, "Random number should be revealed");
        Assert.equal(revealedNumber, rnd_number, "Random number should match");
    }
    */


        // Test for getting the current lottery number
    function testGetCurrentLotteryNo() public {
        uint currentLottery = lottery.getCurrentLotteryNo();
        Assert.equal(currentLottery, createdLotteryId, "Current lottery number should match the created lottery ID");
    }

    // Test for getting the payment token of a lottery
    function testGetPaymentToken() public {
        address ercTokenAddress = lottery.getPaymentToken(createdLotteryId);
        Assert.equal(ercTokenAddress, address(ticketToken), "ERC20 token address should match the ticket token contract address");
    }

    // Test for getting the number of tickets sold in a lottery
    function testGetLotterySales() public {
        // Before any sales, numsold should be 0
        uint ticketsSold = lottery.getLotterySales(createdLotteryId);
        Assert.equal(ticketsSold, 0, "Number of tickets sold should be 0 initially");

        // Simulate ticket sales
        uint quantity = 5;
        bytes32 hashRndNumber = bytes32("randomhash");

        // Mint tokens and purchase tickets
        ticketToken.mint(participant, 10 ether);
        ticketToken.approve(address(lottery), 10 ether);

        //lottery.buyTicketTx(quantity, hashRndNumber);

        // Check the updated number of tickets sold
        ticketsSold = lottery.getLotterySales(createdLotteryId);
        Assert.equal(ticketsSold, quantity, "Number of tickets sold should match the purchased quantity");
    }

    function testGetNumPurchaseTxs() public {
    // Create a lottery
    /* Gerek var mı? Zaten before each var? 
    uint unixEndTime = block.timestamp + 36000;
    uint nooftickets = 100;
    uint noofwinners = 5;
    uint minpercentage = 50;
    uint ticketprice = 2;

    uint lotteryId = lottery.createLottery(
        unixEndTime,
        nooftickets,
        noofwinners,
        minpercentage,
        ticketprice,
        keccak256(abi.encodePacked("hash")),
        "http://example.com"
    );*/

    // Ensure initial purchase transactions are zero
    uint initialNumPurchaseTxs = lottery.getNumPurchaseTxs(createdLotteryId);
    Assert.equal(initialNumPurchaseTxs, 0, "Initial number of purchase transactions should be 0");

    // Simulate ticket purchases
    uint quantity = 3; // Purchase 3 tickets
    bytes32 hashRndNumber = keccak256(abi.encodePacked("randomhash"));

    ticketToken.mint(participant, 10 ether);
    ticketToken.approve(address(lottery), 10 ether);

    for (uint i = 0; i < quantity; i++) {
        //lottery.buyTicketTx(1, hashRndNumber); // Buy tickets one at a time
    }

    // Check updated number of purchase transactions
    uint updatedNumPurchaseTxs = lottery.getNumPurchaseTxs(createdLotteryId);
    Assert.equal(updatedNumPurchaseTxs, quantity, "Number of purchase transactions should match the number of purchases");
}

function testCheckIfAddrTicketWon() public {
    // lottey created with before each
    // Simulate ticket purchases
    uint ticketNo = 1;
    bytes32 hashRndNumber = keccak256(abi.encodePacked("randomhash"));

    ticketToken.mint(participant, 10 ether);
    ticketToken.approve(address(lottery), 10 ether);

    //BUY TICKET MANTIĞI 
    //lottery.buyTicketTx(1, hashRndNumber); // Participant buys a ticket

    // Simulate the end of the lottery
    uint;
    lotteryWinners[0] = ticketNo; // Assume ticket #1 is a winning ticket

    //TODO: LOTTERY BİTİRME MANTIĞI
    //lottery.completeLottery(createdLotteryId, winningTickets);

    // Check if the ticket won
    bool isWinningTicket = lottery.checkIfAddrTicketWon(participant, createdLotteryId, ticketNo);
    Assert.equal(isWinningTicket, true, "Participant's ticket should be a winner");

    // Check with a non-winning ticket number
    bool isNonWinningTicket = lottery.checkIfAddrTicketWon(participant, createdLotteryId, 999);
    Assert.equal(isNonWinningTicket, false, "Participant's non-existent ticket should not be a winner");

    // Check with an address that didn't participate
    bool isUnrelatedWinner = lottery.checkIfAddrTicketWon(address(0x456), createdLotteryId, ticketNo);
    Assert.equal(isUnrelatedWinner, false, "Unrelated address should not have winning tickets");
}
// Test for revealing random number transaction
function testRevealRndNumberTx() public {
    uint lotteryId = createdLotteryId;  // Use the lottery ID created in the testCreateLottery function
    uint sticketNo = 0;  // Ticket number for which random number will be revealed
    uint quantity = 1;   // Quantity of tickets
    bytes32 rndNumber = bytes32("randomhash");  // Random number to reveal for the test
    uint256 hash_rnd_number = uint256(rndNumber);  
    // Mint tokens and approve ticket purchase
    ticketToken.mint(participant, 10 ether);  // Mint tokens for participant
    ticketToken.approve(address(lottery), 10 ether);  // Approve token for lottery contract

    // Reveal the random number for the ticket
    lottery.revealRndNumberTx(lotteryId, sticketNo, quantity, hash_rnd_number);

    // Assert that the random number was revealed
    ////Assert.equal(ticket.revealed, true, "Random number should be revealed");
    //Assert.equal(ticket.hash_rnd_number, rndNumber, "Revealed random number should match the expected random number");

    // Optionally, verify if the ticket's 'revealed' status is updated
    //Assert.equal(ticket.revealed, true, "Ticket revealed status should be true after revealing random number");
}

    // Test for checking if a ticket won
    function testCheckIfMyTicketWon() public {
        uint ticketNo = 1; // Assume the ticket number is 1 for this test case
        uint lotteryNo = createdLotteryId; // Get the created lottery ID
        bool expectedWinnerStatus = false; // Assume ticket has not won initially

        // Mint tokens and purchase the ticket
        ticketToken.mint(participant, 10 ether);
        ticketToken.approve(address(lottery), 10 ether);
       // lottery.buyTicketTx(1, keccak256(abi.encodePacked("randomhash")));

        // Assuming we simulate that ticket #1 has won
        lotteryWinners.push(ticketNo);  // Add ticket #1 to the winners list

        // Check if the ticket won
        bool isWinner = lottery.checkIfMyTicketWon(lotteryNo, ticketNo);

        // Assert that the ticket has won
        Assert.equal(isWinner, true, "Ticket should be a winner");

        // Check if a non-winning ticket is correctly identified
        uint nonWinningTicketNo = 999;  // Ticket #999 does not exist
        bool isNonWinner = lottery.checkIfMyTicketWon(lotteryNo, nonWinningTicketNo);
        Assert.equal(isNonWinner, false, "Non-existent ticket should not be a winner");
    }


}
