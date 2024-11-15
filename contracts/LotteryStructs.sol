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
        INACTIVE,       // 0: Lottery is not yet started
        ACTIVE,         // 1: Lottery is ongoing and tickets can be purchased
        CLOSED,         // 2: Lottery has ended and ticket purchase is not available
        COMPLETED,      // 3: Lottery is completed and the winner is revealed
        CANCELED        // 4: Lottery is cancelled
    }

    /*
        Struct representing a single lottery's information.
     */
    struct LotteryInfo {
        uint unixbeg;           // Start time of the lottery (in Unix timestamp)
        uint32 noOfTickets;     // Total number of tickets in the lottery
        uint noOfWinners;       // Number of winners to be selected
        uint16 minPercentage;   // Minimum percentage of tickets to be sold for the lottery to be valid
        uint ticketPrice;       // Price of each ticket (in the NBG Token)
        uint32 soldTickets;     // Number of tickets sold
        LotteryState state;     // Current state of the lottery
        uint32 transactions;
        //bytes32 htmlhash;       // Hash of the lottery details page (will be used for off-chain data verification)
        //string url;             // URL of the lottery details page (when needed)
        address paymentToken;   // Address of the NBG Token contract used for payments
    }

    /*
        Struct representing details about a purchased ticket or tickets.
     */
    struct TicketInfo {
        address participant;        // Address of the user who purchased the ticket(s)
        uint8 quantity;             // Number of tickets purchased in this transaction - Max 30 can be sold
        bytes32 hash_rnd_number;    // Commitment hash of a random number (used for fair lottery mechanics)
        bool revealed;              // Indicates if the participant has revealed their random number
    }
}
