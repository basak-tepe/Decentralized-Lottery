// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LotteryStructs.sol"; // Import the existing LotteryStructs library
import "../TicketToken.sol"; // Import the ERC20 token contract interface

/**
 * LotteryStorage
 * This library manages the storage layout for the Lottery system in a Diamond architecture.
 * It avoids storage collision by using a fixed storage position.
 */
library LotteryStorage {
    // Define a unique storage position using a keccak256 hash.
    // This ensures no collisions with other libraries or facets.
    bytes32 constant STORAGE_POSITION = keccak256("diamond.storage.lottery");

    /**
     * @dev Struct to hold the state variables for the Lottery system.
     * This includes mappings and counters for managing lotteries and tickets.
     */
    struct State {
        address owner; // The owner of the contract
        bool accessControlInitialized; // Flag to prevent re-initialization
        mapping(uint => LotteryStructs.Lottery) lotteries; // Mapping of lottery ID to Lottery details
        mapping(uint => LotteryStructs.Ticket[]) lotteryTickets; // Mapping of lottery ID to its tickets
        uint currentLotteryNo; // Counter to track the current lottery number
        TicketToken paymentToken;
    }

    /**
     * @dev Internal function to access the storage struct.
     * This ensures consistent access to the same storage layout.
     * @return s A reference to the `State` struct in storage.
     */
    function getStorage() internal pure returns (State storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    /**
     * @dev Function to add a new lottery to storage.
     * @param lotteryId The ID of the new lottery.
     * @param lottery The details of the lottery to store.
     */
    function addLottery(uint lotteryId, LotteryStructs.Lottery memory lottery) internal {
        State storage s = getStorage();
        s.lotteries[lotteryId] = lottery;
    }

    /**
     * @dev Function to retrieve a lottery by its ID.
     * @param lotteryId The ID of the lottery to retrieve.
     * @return A reference to the `Lottery` struct.
     */
    function getLottery(uint lotteryId) internal view returns (LotteryStructs.Lottery storage) {
        State storage s = getStorage();
        return s.lotteries[lotteryId];
    }

    /**
     * @dev Function to update the current lottery number.
     * @param newLotteryNo The new lottery number to set.
     */
    function updateCurrentLotteryNo(uint newLotteryNo) internal {
        State storage s = getStorage();
        s.currentLotteryNo = newLotteryNo;
    }

    /**
     * @dev Function to retrieve the current lottery number.
     * @return The current lottery number.
     */
    function getCurrentLotteryNo() public view returns (uint) {
        State storage s = getStorage();
        return s.currentLotteryNo;
    }

    /**
     * @dev Function to add a ticket to a specific lottery.
     * @param lotteryId The ID of the lottery.
     * @param ticket The ticket details to add.
     */
    function addTicket(uint lotteryId, LotteryStructs.Ticket memory ticket) internal {
        State storage s = getStorage();
        s.lotteryTickets[lotteryId].push(ticket);
    }

    /**
     * @dev Function to retrieve all tickets for a specific lottery.
     * @param lotteryId The ID of the lottery.
     * @return An array of `Ticket` structs.
     */
    function getTickets(uint lotteryId) internal view returns (LotteryStructs.Ticket[] storage) {
        State storage s = getStorage();
        return s.lotteryTickets[lotteryId];
    }
}