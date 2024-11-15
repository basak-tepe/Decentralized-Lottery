// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./LotteryStructs.sol";  // Importing LotteryStructs.sol

/*
    Custom ERC20 token for the lottery system.
*/
contract TicketToken is ERC20 {
    address public owner; // address of the contract owner

    /*
        Sets up the token with a name and symbol, and assigns the owner.
        Inherits ERC20 constructor for token initialization
    */
    constructor() ERC20("NuBaGo Token", "NBG") {
        owner = msg.sender;
    }

    /*
        // TODO: enough?
        @param to the address to receive the tokens
        @param amount number of tokens to get
    */
    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "Only the owner can mint tickets");
        _mint(to, amount);
    }
}

/*
    This contract manages lotteries using ERC20 token.
    TODO: Explain more
*/
contract NBGLottery {

    TicketToken public ticketToken;
    address public owner;

    /*
        Sets the owner and initializes TicketToken contract.
        @param _ticketTokenAddress address of the deployed TicketToken contract
    */
    constructor(address _ticketTokenAddress) {
        owner = msg.sender;
        ticketToken = TicketToken(_ticketTokenAddress);
    }
}