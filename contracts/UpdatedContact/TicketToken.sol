// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract  TicketToken is ERC20 {
    uint256 private constant MAX_UINT256 = 2**256 - 1;

    // Mapping to store balances and allowances
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // Constructor to initialize the token
    constructor(uint256 initialSupply) ERC20("NuBaGo Token", "NBG") {
        _mint(msg.sender, initialSupply);   // Give the creator all initial tokens
    }
    
    // Transfer function to transfer tokens from sender to recipient
    function transfer(address _to, uint256 amount) public override returns (bool) {
        require(balances[msg.sender] >= amount, "NBG: transfer amount exceeds balance");
        balances[msg.sender] -= amount;
        balances[_to] += amount;
        emit Transfer(msg.sender, _to, amount);
        return true;
    }

    // TransferFrom function to transfer tokens on behalf of another address (spender)
    function transferFrom(address _from, address _to, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = allowances[_from][msg.sender];

        require(balances[_from] >= amount, "NBG: transfer amount exceeds balance");
        require(currentAllowance >= amount, "NBG: transfer amount exceeds allowance");

        balances[_from] -= amount;
        balances[_to] += amount;

        if (currentAllowance < MAX_UINT256) {
            allowances[_from][msg.sender] -= amount;
        }

        emit Transfer(_from, _to, amount);
        return true;
    }
    // Allowance function to check the allowance for a spender
    function allowance(address owner, address spender) public view override returns (uint256 remaining) {
        return allowances[owner][spender];
    }

    // Balance of function to get the balance of an address
    function balanceOf(address account) public view override returns (uint256 balance) {
        return balances[account];
    }
    // Approve function to approve a spender to transfer tokens on behalf of the owner
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

}
