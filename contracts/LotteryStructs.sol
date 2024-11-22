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
        PURCHASE,         // 1: Lottery is ongoing and tickets can be purchased
        REVEAL,         // 2: Lottery has ended and it is number submission time
        COMPLETED,      // 3: Lottery is completed and the winner is revealed
        CANCELLED        // 4: Lottery is cancelled
    }

    /*
        Struct representing a single lottery's information.
     */
    struct LotteryInfo {
        uint unixbeg;           // End time of the lottery (in Unix timestamp)
        uint nooftickets;       // Total number of tickets in the lottery
        uint noofwinners;       // Number of winners to be selected
        uint minpercentage;     // Minimum percentage of tickets to be sold for the lottery to be valid
        uint ticketprice;       // Price of each ticket (in the NBG Token)
        uint numsold;           // Number of tickets sold
        LotteryState state;     // Current state of the lottery
        uint numpurchasetxs;    // Number of purchase transactions.
        uint sticketno;         // Which ticket are we distributing RN.
        bytes32 htmlhash;       // Hash of the lottery details page (will be used for off-chain data verification)
        string url;             // URL of the lottery details page (when needed)
        address erctokenaddr;   // Address of the NBG Token contract used for payments
        uint revealStartTime; // Start time for random number reveal
        uint[] lotteryWinners;
        uint[] randomNumbers;
    }

    /*
        Struct representing details about a purchased ticket or tickets.
     */
    struct TicketInfo {
        address participant;        // Address of the user who purchased the ticket(s)
        uint quantity;             // Number of tickets purchased in this transaction - Max 30 can be sold
        bytes32 hash_rnd_number;    // Commitment hash of a random number (used for fair lottery mechanics)
        bool revealed;              // Indicates if the participant has revealed their random number
    }
}
