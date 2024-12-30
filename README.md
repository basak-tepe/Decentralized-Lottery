# DECENTRALIZED LOTTERY

## Overview

The `NuBaGo Lottery Contract` enables the creation and management of a decentralized lottery system using an ERC20 token (`NuBaGo Token - NBG`) for ticket purchases. This system allows for multiple lotteries, where users can purchase tickets, reveal random numbers, and eventually determine the winners. The contract handles the minting of tokens, ticket purchases, lottery state management, and winner determination.

Contract provides a robust and decentralized lottery system powered by the NuBaGo Token (NBG), allowing for secure ticket purchases, random number generation, winner determination, and refund handling. It ensures fairness and transparency in lottery operations.

### Key Features
- **Custom ERC20 Token**: The contract utilizes the `TicketToken` ERC20 token (NuBaGo Token - NBG) for lottery ticket purchases.
- **Lottery Creation**: Owners can create lotteries with configurable parameters such as the number of tickets, winners, minimum ticket sales percentage, and ticket price.
- **Ticket Purchases**: Users can purchase lottery tickets with NBG tokens, which are recorded and tracked by the contract.
- **Random Number Generation**: Users submit a hash of a random number, which is revealed later to determine winners.
- **Lottery States**: The lottery goes through different states: `PURCHASE`, `REVEAL`, `COMPLETED`, and `CANCELLED`. The contract can automatically transition between these states based on time and conditions (e.g., minimum ticket sales percentage).
- **Winner Determination**: Winners are determined through a random process by XOR'ing the random numbers revealed by participants.
- **Refunds**: If a lottery is canceled due to insufficient ticket sales, participants can request refunds for their tickets.

---

## Contract Breakdown

### TicketToken Contract
This is a custom ERC20 token used for the lottery. The contract owner can mint new tokens to be distributed to participants.

**Functions**:
- `mint(address to, uint256 amount)`: Allows the owner to mint new tokens and send them to a specified address.

### CompanyLotteries Contract
The main contract managing the lottery system. It tracks multiple lotteries and their participants, ticket sales, and manages state transitions.

**Key Variables**:
- `ticketToken`: Reference to the deployed `TicketToken` contract.
- `currentLotteryNo`: Tracks the current lottery number.
- `lotteries`: A mapping of lottery numbers to lottery details.
- `lotteryTickets`: A mapping of lottery numbers to an array of ticket information.
- `addressToTickets`: A mapping of user addresses to the list of ticket numbers they hold for each lottery.

**Key Events**:
- `LotteryCreated`: Emitted when a new lottery is created.
- `TicketPurchased`: Emitted when a user purchases a ticket.
- `RandomNumberRevealed`: Emitted when a user reveals their random number.
- `RefundWithdrawn`: Emitted when a user withdraws a refund.
- `LotteryStateUpdated`: Emitted when the lottery state is updated.

---

### Functions

#### Lottery Management:
- `createLottery(...)`: Allows the owner to create a new lottery with parameters such as ticket price, number of winners, and minimum participation.
- `updateLotteryState(uint256 lottery_no)`: Updates the lottery state based on conditions like the number of tickets sold, current time, and other rules.
  
#### Ticket Purchases:
- `buyTicketTx(uint256 lottery_no, uint256 quantity, bytes32 hash_rnd_number)`: Allows users to buy tickets for a specific lottery, providing a hash of a random number.
  
#### Random Number Reveal:
- `revealRndNumberTx(uint256 lottery_no, uint256 sticketno, uint256 quantity, uint256 rnd_number)`: Users reveal their random numbers which will be used to determine the lottery winners.

#### Winner Determination:
- `determineWinners(uint256 lottery_no)`: Calculates the lottery winners by XOR'ing all the revealed random numbers.

#### Refunds:
- `withdrawTicketRefund(uint256 lottery_no, uint256 sticketNo)`: Allows users to withdraw a refund for their tickets if the lottery is canceled.

#### Lottery Information:
- `getLotteryInfo(uint256 lottery_no)`: Retrieves essential information about a lottery.
- `getLotterySales(uint256 lottery_no)`: Returns the number of tickets sold for a specific lottery.
- `getIthWinningTicket(uint256 lottery_no, uint256 i)`: Returns the ticket number of the ith winning ticket for a lottery.
- `checkIfMyTicketWon(uint256 lottery_no, uint256 ticketNo)`: Checks if a specific ticket is a winner.
  
#### Payment Token:
- `setPaymentToken(address ercTokenAddr)`: Sets the payment token for the current lottery (ERC20 token).
- `getPaymentToken(uint256 lottery_no)`: Returns the address of the payment token for a specific lottery.

#### Ticket Proceeds:
- `withdrawTicketProceeds(uint256 lottery_no)`: Allows the owner to withdraw the proceeds from ticket sales once the lottery has been completed.

---

## Lottery States
The lottery goes through several states:
1. **PURCHASE**: Lottery is active and users can purchase tickets.
2. **REVEAL**: Users can reveal their random numbers.
3. **COMPLETED**: Lottery is complete and winners have been determined.
4. **CANCELLED**: Lottery is canceled due to insufficient ticket sales.

---

## Usage

1. **Deploy the TicketToken Contract**:
   - Deploy the `TicketToken` contract (NuBaGo Token - NBG) for the lottery.

2. **Deploy the CompanyLotteries Contract**:
   - Deploy the `CompanyLotteries` contract by providing the address of the deployed `TicketToken` contract.

3. **Create a Lottery**:
   - Call `createLottery` with desired parameters to start a new lottery.

4. **Purchase Tickets**:
   - Users can buy tickets by calling `buyTicketTx`, providing the lottery number and the quantity of tickets.

5. **Reveal Random Numbers**:
   - After purchasing, users can reveal their random numbers via `revealRndNumberTx`.

6. **Determine Winners**:
   - Once the lottery is completed, the owner can call `determineWinners` to select the winners.

7. **Withdraw Proceeds**:
   - After the lottery ends, the owner can withdraw ticket proceeds via `withdrawTicketProceeds`.

8. **Refunds**:
   - If a lottery is canceled, users can withdraw refunds for their tickets via `withdrawTicketRefund`.

---

# Licence
This contract is licensed under the MIT License.
