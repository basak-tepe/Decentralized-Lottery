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
}
