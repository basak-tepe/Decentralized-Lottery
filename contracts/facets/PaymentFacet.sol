// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LotteryStorage.sol";
import "../TicketToken.sol";
import "./AccessControlFacet.sol";

/**
 * PaymentFacet
 * Facet responsible for managing payments, including setting tokens, retrieving balances, and withdrawing proceeds.
 */
contract PaymentFacet {

    // Modifier to control functions that can be called by the owner only
    modifier onlyOwner() {
        require(msg.sender == AccessControlFacet(address(this)).getOwner(), "Only the owner can call this function");
        _;
    }

    // Modifier to control lottery number
    modifier lotteryControl(uint lottery_no) {
        LotteryStorage.State storage s = LotteryStorage.getStorage();
        require(lottery_no > 0 && lottery_no-1 <= s.currentLotteryNo, "Invalid lottery number");
        _;
    }

    /**
    * Allows the contract owner to set or update the address of the ERC20 token used for ticket purchases.
    * @param erctokenaddr The address of the new ERC20 token contract to be used for ticket payments.
    */
    function setPaymentToken(address erctokenaddr) public onlyOwner {
        require(erctokenaddr != address(0), "Invalid token address");

        LotteryStorage.State storage s = LotteryStorage.getStorage();
        TicketToken ticketToken = TicketToken(erctokenaddr);

        // Perform a sanity check on the token
        require(ticketToken.totalSupply() > 0, "Invalid token contract");

        // Set the new ERC20 token address
        s.paymentToken = ticketToken;
    }

    /**
    * Retrieves the ERC20 token address used for ticket purchases in a specific lottery.
    * @param lottery_no The ID of the lottery for which the payment token address is being retrieved.
    * @return erctokenaddr The ERC20 token address used for ticket purchases in the specified lottery.
    */
    function getPaymentToken(uint lottery_no)
        public
        view
        lotteryControl(lottery_no)
        returns (address erctokenaddr) {
        LotteryStorage.State storage s = LotteryStorage.getStorage();
        return address(s.paymentToken); // Return the ERC20 token address used for ticket purchases in the specified lottery
    }

    /**
    * Allows the contract owner to withdraw the ticket proceeds from a specific lottery.
    * This function is only callable by the contract owner and will transfer the proceeds to the owner's address.
    * @param lottery_no The ID of the lottery for which the proceeds are being withdrawn.
    */
    function withdrawTicketProceeds(uint lottery_no)
        public
        onlyOwner
        lotteryControl(lottery_no) {

        LotteryStorage.State storage s = LotteryStorage.getStorage();
        LotteryStructs.Lottery storage lottery = s.lotteries[lottery_no-1];

        require(lottery.state == LotteryStructs.LotteryState.COMPLETED, "Lottery has not been completed");
        require(lottery.numsold > 0, "No tickets sold");

        // Calculate the total ticket sales proceeds
        uint256 totalProceeds = lottery.numsold * lottery.ticketprice;

        // Check if the contract has sufficient balance
        TicketToken ticketToken = TicketToken(address(s.paymentToken));
        uint256 contractBalance = ticketToken.balanceOf(address(this));
        require(contractBalance >= totalProceeds, "Insufficient funds");

        // Transfer the ticket proceeds to the contract owner
        address owner = AccessControlFacet(address(this)).getOwner();
        require(ticketToken.transfer(owner, totalProceeds), "Transfer failed");
    }
}