// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RSOptionsRewards is AccessControl, Pausable {
    bytes32 public constant REWARDS_ADMIN = keccak256("REWARDS_ADMIN");
    
    struct Option {
        uint256 amount;
        uint256 strikePrice;
        uint256 expiry;
        bool exercised;
        OptionType optionType;
    }
    
    enum OptionType {
        TEAM,           // 1M allocation
        LP_INCENTIVE,   // 40M allocation
        ANNUAL_BONUS    // 21M allocation
    }
    
    mapping(address => Option[]) public userOptions;
    mapping(OptionType => uint256) public totalAllocated;
    
    event OptionIssued(address indexed user, uint256 amount, OptionType optionType);
    event OptionExercised(address indexed user, uint256 amount, uint256 strikePrice);
    
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(REWARDS_ADMIN, msg.sender);
    }

    // Options rewards logic will go here
}
