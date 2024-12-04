// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TicketToken is ERC20 {
    // Constructor to initialize the token
    constructor(uint256 initialSupply) ERC20("NuBaGo Token", "NBG") {
        _mint(msg.sender, initialSupply); // Mint initial tokens to the contract deployer
    }
}

