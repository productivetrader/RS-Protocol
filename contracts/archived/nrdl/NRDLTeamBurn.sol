// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NRDLTeamBurn is Ownable {
    IERC20 public rdlToken;
    address public constant BURN_ADDRESS = address(0);
    
    event TeamTokensBurned(uint256 amount);
    
    constructor(address _rdlToken) {
        rdlToken = IERC20(_rdlToken);
    }
    
    function burnTeamAllocation() external onlyOwner {
        uint256 teamBalance = rdlToken.balanceOf(address(this));
        require(teamBalance > 0, "No tokens to burn");
        
        // Transfer to burn address
        rdlToken.transfer(BURN_ADDRESS, teamBalance);
        
        emit TeamTokensBurned(teamBalance);
    }
    
    // Optional: Partial burn
    function burnPartialTeamAllocation(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        uint256 teamBalance = rdlToken.balanceOf(address(this));
        require(teamBalance >= amount, "Insufficient balance");
        
        // Transfer to burn address
        rdlToken.transfer(BURN_ADDRESS, amount);
        
        emit TeamTokensBurned(amount);
    }
} 