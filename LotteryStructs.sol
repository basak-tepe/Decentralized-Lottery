// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LotteryStructs {

    // Enum to represent the different states a lottery can be in
    enum LotteryState {
        INACTIVE,   // Lottery has not started
        ACTIVE,     // Lottery is currently active and tickets can be purchased
        CLOSED,     // Lottery is closed, no more tickets can be purchased
        COMPLETED,  // Lottery has ended and winners have been drawn
        CANCELED    // Lottery has been canceled, refunds may be issued
    }

    // Struct to store information about each lottery
    struct LotteryInfo {
        uint unixbeg;           // Start time of the lottery in Unix timestamp
        uint nooftickets;       // Total number of tickets available
        uint noofwinners;       // Number of winners for this lottery
        uint minpercentage;     // Minimum percentage of tickets to be sold for the lottery to be valid
        uint ticketprice;       // Price of each ticket in the specified token
        uint soldTickets;       // Count of tickets sold
        LotteryState state;     // Current state of the lottery (INACTIVE, ACTIVE, etc.)
        bytes32 htmlhash;       // Hash of the lottery details page for verification
        string url;             // URL to the lottery details page
        address paymentToken;   // ERC20 token used for payment
    }

    // Struct to store information about each purchased ticket
    struct TicketInfo {
        address participant;        // Address of the ticket buyer
        uint quantity;              // Quantity of tickets purchased in the transaction
        bytes32 hash_rnd_number;    // Hash of the random number (used as a commitment for fair revealing)
        bool revealed;              // Indicates if the random number has been revealed
    }
}
