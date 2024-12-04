// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "remix_tests.sol"; // Import Remix's test library
import "../contracts/CompanyLotteries.sol";
import "../contracts/LotteryStructs.sol";
import "../contracts/TicketToken.sol";


contract CompanyLotteriesTest {
    uint testRound = 20;
    TicketToken private ticketToken;
    CompanyLotteries private companyLotteries;
    bytes32 htmlhash = keccak256(abi.encodePacked("1"));
    string   url= "https://example.com/lottery";
    // Initial setup before tests
    function beforeAll() public {
        // Deploy the TicketToken contract with an initial supply
        ticketToken = new TicketToken(1000000);
        // Deploy the CompanyLotteries contract with the token address
        companyLotteries = new CompanyLotteries(address(ticketToken));
    }

   
    // Test for revealRndNumberTx function
    function testRevealRndNumberTx() public {
        // First, create a lottery for testing purpose with some predefined parameters
        uint unixbeg = block.timestamp + 60 seconds; // Start time
        uint nooftickets = 100;
        uint noofwinners = 3;
        uint minpercentage = 50;
        uint ticketprice = 10;

        // Create the lottery
        uint ticketNo = companyLotteries.createLottery(
            unixbeg, 
            nooftickets, 
            noofwinners, 
            minpercentage, 
            ticketprice, 
            htmlhash, 
            url
        );

        // Now, simulate buying a ticket for the lottery
        bytes32 hash_rnd_number = keccak256(abi.encodePacked("1")); 
        companyLotteries.buyTicketTx(1, 5, hash_rnd_number);
        // Compare the enum state correctly
        Assert.equal(uint(LotteryStructs.LotteryState.PURCHASE), uint(companyLotteries.getLotteryState(1)), "PURCHASE STATE");

        //simulateTimeAdvance(30);
        
        companyLotteries.updateLotteryStates(); // Trigger state update manually
        // Compare the enum state correctly
        Assert.equal(uint(LotteryStructs.LotteryState.REVEAL), uint(companyLotteries.getLotteryState(1)), "REVEAL STATE");

    }

    // Helper function to simulate time advancement
    function simulateTimeAdvance(uint secondsToAdvance) public {
        uint newTime = block.timestamp + secondsToAdvance;    
    }

}


