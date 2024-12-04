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

    uint256 public currentLotteryNo;
    uint unixbeg;
    uint nooftickets;
    uint noofwinners;
    uint minpercentage;
    uint ticketprice;
    uint numpurchasetxs;
    uint numsold;  
    uint quantity;
    uint testStartTime;
    uint newTime ;
    bytes32 htmlhash = keccak256(abi.encodePacked("1"));
    string   url= "https://example.com/lottery";
    uint ticketNo;

    // Initial setup before tests
    function beforeAll() public {
        // Deploy the TicketToken contract with an initial supply
        ticketToken = new TicketToken(1000000);

        // Deploy the CompanyLotteries contract with the token address
        companyLotteries = new CompanyLotteries(address(ticketToken));
    }

    /// #sender: account-0
    /// #value: 0
    function testCreateLottery() public {

        for (uint i= 0  ; i< testRound ; i++) {
        // Input parameters for createLottery
            testStartTime = block.timestamp;
            unixbeg = (block.timestamp+ i*10)  + 120 seconds; // 1 day from now
            nooftickets = i+100;
            noofwinners = i+1;
            minpercentage = 50;
            ticketprice = i + 10;
            currentLotteryNo++;

            ticketNo = companyLotteries.createLottery(
                unixbeg,
                nooftickets,
                noofwinners,
                minpercentage,
                ticketprice,
                htmlhash,
                url
            );
            // Assert the returned lottery_no is as expected (first lottery should have ID 0)
            Assert.equal(currentLotteryNo, companyLotteries.getCurrentLotteryNo(), "Lottery number error");
            // Check the lottery info
            (uint unixStart, uint numTickets, uint numWinners, uint minPercent, uint price) = companyLotteries.getLotteryInfo(currentLotteryNo);
            Assert.equal(numTickets, nooftickets, "Number of tickets should match");
            Assert.equal(numWinners, noofwinners, "Number of winners should match");
            Assert.equal(minPercent, minpercentage, "Minimum participation percentage should match");
            Assert.equal(price, ticketprice, "Ticket price should match");
        }
    }


    function testBuyTicketTx() public {
        // Parameters for buying a ticket
        uint sticketno;
        uint soldNum;
        uint lotteryNo;
        numsold = 0;
        quantity = 0;
        bytes32 hash_rnd_number = keccak256(abi.encodePacked("randomSeed")); 
        for (uint i= 0  ; i< testRound ; i++) {
            // Parameters for buying a ticket
            quantity = i+1; 

            lotteryNo= companyLotteries.getCurrentLotteryNo();
            Assert.equal(lotteryNo, currentLotteryNo, "Current lottery number should match the created lottery ID");

            sticketno = companyLotteries.buyTicketTx(i+1, quantity, hash_rnd_number);
            numpurchasetxs = companyLotteries.getNumPurchaseTxs(i+1);
            Assert.equal(sticketno, numpurchasetxs, "The ticket number not matched");

            soldNum = companyLotteries.getLotterySales(i+1);
            Assert.equal(quantity, soldNum, "The number of tickets sold not matched");
            
            sticketno = companyLotteries.buyTicketTx(i+1, quantity, hash_rnd_number);
            numpurchasetxs = companyLotteries.getNumPurchaseTxs(i+1);
            Assert.equal(sticketno, numpurchasetxs, "The ticket number not matched");

            soldNum = companyLotteries.getLotterySales(i+1);
            Assert.equal(2*quantity, soldNum, "The number of tickets sold not matched"); 
        }
    }    
   
  // Test for getting the current lottery number
    function testGetCurrentLotteryNo() public {
        uint currentLottery = companyLotteries.getCurrentLotteryNo();
        Assert.equal(currentLottery, currentLotteryNo, "Current lottery number should match the created lottery ID");
    }

    // Test for getting the payment token of a lottery
    function testGetPaymentToken() public {
        address ercTokenAddress = companyLotteries.getPaymentToken(currentLotteryNo);
        Assert.equal(ercTokenAddress, address(ticketToken), "ERC20 token address should match the ticket token contract address");
    }
 
    function testSetPaymentToken() public {
        address newTokenAddress = 0xAb54680ec58C217002c15f1D43a3B5cAf31c30C8;  // Replace with a valid token address
        companyLotteries.setPaymentToken(newTokenAddress);
        // Retrieve the token address after the update
        address currentTokenAddress = companyLotteries.getPaymentToken(currentLotteryNo);
        // Assert that the token address was correctly updated
        Assert.equal(currentTokenAddress, newTokenAddress, "The token address should be updated");
    }

    // Function to test the getLotteryURL function
    function testGetLotteryURL() public {
        bytes32 gethtmlhash ;
        string  memory geturl ;
        for (uint i= 0  ; i< testRound ; i++) {
            (gethtmlhash, geturl) = companyLotteries.getLotteryURL(i+1);
            Assert.equal(htmlhash, gethtmlhash, "Hash not matched");
            Assert.equal(url, geturl, "Hash not matched");
        }     
    }  

    // Test for updating lottery states (e.g., PURCHASE -> REVEAL -> COMPLETED)
    function testUpdateLotteryStates() public {
        // Simulate transition to REVEAL 
        simulateTimeAdvance(15); 
        companyLotteries.updateLotteryStates(); // Trigger state update manually  
       
    }

    // Helper function to simulate time advancement
    function simulateTimeAdvance(uint secondsToAdvance) private {
        newTime = block.timestamp + secondsToAdvance;    
    }


}


