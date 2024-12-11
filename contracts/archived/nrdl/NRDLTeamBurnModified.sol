// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NRDLTeamBurnModified is Ownable {
    IERC20 public rdlToken;
    uint256 public constant ORIGINAL_TEAM_ALLOCATION = 9_000_000 * 1e18;
    uint256 public constant NEW_TEAM_ALLOCATION = 1_000_000 * 1e18;
    mapping(address => bool) public hasTeamMemberClaimed;
    
    event TeamAllocationReduced(uint256 burnedAmount);
    event TeamMemberClaimed(address indexed member, uint256 amount);
    
    constructor(address _rdlToken) {
        rdlToken = IERC20(_rdlToken);
    }
    
    function reduceTeamAllocation() external onlyOwner {
        uint256 teamBalance = rdlToken.balanceOf(address(this));
        require(teamBalance >= ORIGINAL_TEAM_ALLOCATION, "Invalid team balance");
        
        uint256 burnAmount = ORIGINAL_TEAM_ALLOCATION - NEW_TEAM_ALLOCATION;
        rdlToken.transfer(address(0), burnAmount);
        
        emit TeamAllocationReduced(burnAmount);
    }
    
    // Team members must claim within timeframe
    uint256 public claimDeadline;
    
    function setClaimDeadline(uint256 _deadline) external onlyOwner {
        require(_deadline > block.timestamp, "Invalid deadline");
        claimDeadline = _deadline;
    }
    
    function claimTeamAllocation(address teamMember) external onlyOwner {
        require(block.timestamp <= claimDeadline, "Claim period ended");
        require(!hasTeamMemberClaimed[teamMember], "Already claimed");
        
        uint256 individualAllocation = NEW_TEAM_ALLOCATION / 9; // Assuming 9 team members
        rdlToken.transfer(teamMember, individualAllocation);
        
        hasTeamMemberClaimed[teamMember] = true;
        emit TeamMemberClaimed(teamMember, individualAllocation);
    }
} 