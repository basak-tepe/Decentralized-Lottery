// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
    This library provides a set of data structures to manage and organize information required for a
    lottery system. Library has a LotteryInfo struct to manage lottery information and TicketInfo
    struct for tickets. It can also has an enum to define and manage lottery's state.
*/
library LotteryStructs {

    /*
      Enum representing the various states a lottery can go through.
     */
    enum LotteryState {
        PURCHASE,       // 1: Lottery is ongoing and tickets can be purchased
        REVEAL,         // 2: Lottery has ended and it is number submission time
        COMPLETED,      // 3: Lottery is completed and the winner is revealed
        CANCELLED       // 4: Lottery is cancelled
    }

    /*
        Struct representing a single lottery's information.
    */
    struct Lottery{
        uint unixbeg;           // End time of the lottery (in Unix timestamp)
        uint nooftickets;       // Number of tickets issued
        uint noofwinners;       // Number of winners
        uint minpercentage;     // Minimum percentage of the tickets 
                                // that need to be purchased in order to let the lottery run 
        uint ticketprice;       // Price of each ticket (in the NBG Token)      
        bytes32 htmlhash;       // Hash of the contents of the html page that describes the lottery.
        string url;             // URL of the html page that describes the lottery
        uint  revealStartTime;  // Start time for random number reveal
        bool exists;            // TO avoid unintentionally modifying a nonexistent lottery entry.
        LotteryState state;     // Current state of the lottery
        uint numsold;           // Number of tickets sold
        uint numpurchasetxs;    // Number of purchase transactions.
        uint currentRandom;     // To determine winners.
        uint[] lotteryWinners;
        Ticket[] tickets;       

    }

    /*
        Struct representing details about a purchased ticket or tickets.
    */
    struct Ticket {
        address owner;        // Address of the user who purchased the ticket(s)
        uint quantity;        // Number of tickets purchased in this transaction - Max 30 can be sold
        bytes32 hash;         // Commitment hash of a random number (used for fair lottery mechanics)
        bool revealed;        // Indicates if the participant has revealed their random number
        bool redeemed;        // Indicates if the participant has got 
    }


}
