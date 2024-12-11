// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPriceOracle.sol";

contract RSOptionsRewards is ReentrancyGuard, Ownable {
    struct Option {
        uint256 amount;          // Amount of RS tokens
        uint256 strikePrice;     // Exercise price
        uint256 issuanceTime;    // When option was created
        uint256 expiryTime;      // When option expires
        address paymentToken;    // USDC or S
        bool exercised;          // If already used
    }

    IERC20 public immutable rsToken;
    IPriceOracle public priceOracle;
    
    // Supported payment tokens (USDC and Sonic)
    mapping(address => bool) public supportedPaymentTokens;
    
    // Discount configurations for rewards
    uint256 public constant STRIKE_DISCOUNT_USDC = 20;  // 20% below market
    uint256 public constant STRIKE_DISCOUNT_SONIC = 25; // 25% below market
    
    // Time configuration
    uint256 public constant MAX_DURATION = 72 hours;    // Maximum exercise window
    uint256 public optionDuration = 24 hours;          // Default duration, adjustable
    
    // Track options by user
    mapping(address => Option[]) public userOptions;
    
    // Events
    event OptionIssued(
        address indexed user,
        uint256 amount,
        uint256 strikePrice,
        address paymentToken,
        uint256 expiryTime
    );
    
    event OptionExercised(
        address indexed user,
        uint256 optionId,
        uint256 amount,
        uint256 paymentAmount
    );

    constructor(
        address _rsToken,
        address _priceOracle,
        address _usdc,
        address _sonic
    ) {
        rsToken = IERC20(_rsToken);
        priceOracle = IPriceOracle(_priceOracle);
        supportedPaymentTokens[_usdc] = true;
        supportedPaymentTokens[_sonic] = true;
    }

    // Called by MasterChef to issue options as rewards
    function issueOptionReward(
        address user,
        uint256 amount,
        address paymentToken
    ) external onlyOwner {
        require(supportedPaymentTokens[paymentToken], "Unsupported payment token");
        
        uint256 marketPrice = priceOracle.getPrice(address(rsToken), paymentToken);
        uint256 discount = paymentToken == address(SONIC) ? 
            STRIKE_DISCOUNT_SONIC : STRIKE_DISCOUNT_USDC;
            
        uint256 strikePrice = marketPrice * (100 - discount) / 100;
        
        Option memory newOption = Option({
            amount: amount,
            strikePrice: strikePrice,
            issuanceTime: block.timestamp,
            expiryTime: block.timestamp + optionDuration,
            paymentToken: paymentToken,
            exercised: false
        });
        
        userOptions[user].push(newOption);
        
        emit OptionIssued(
            user,
            amount,
            strikePrice,
            paymentToken,
            newOption.expiryTime
        );
    }

    // Exercise an option
    function exerciseOption(uint256 optionId) external nonReentrant {
        require(optionId < userOptions[msg.sender].length, "Invalid option ID");
        Option storage option = userOptions[msg.sender][optionId];
        
        require(!option.exercised, "Option already exercised");
        require(block.timestamp <= option.expiryTime, "Option expired");
        
        uint256 paymentRequired = option.amount * option.strikePrice / 1e18;
        
        // Transfer payment token (USDC or S)
        IERC20(option.paymentToken).transferFrom(
            msg.sender,
            address(this),
            paymentRequired
        );
        
        // Transfer RS tokens
        rsToken.transfer(msg.sender, option.amount);
        
        option.exercised = true;
        
        emit OptionExercised(
            msg.sender,
            optionId,
            option.amount,
            paymentRequired
        );
        
        // Add liquidity to respective pool
        _addLiquidity(option.paymentToken, paymentRequired, option.amount);
    }

    // Internal function to add liquidity
    function _addLiquidity(
        address paymentToken,
        uint256 paymentAmount,
        uint256 rsAmount
    ) internal {
        // Implementation will depend on DEX interface
        // This will automatically add to RS/USDC or RS/S pool
    }

    // Admin functions
    function setOptionDuration(uint256 newDuration) external onlyOwner {
        require(newDuration <= MAX_DURATION, "Exceeds maximum duration");
        optionDuration = newDuration;
    }

    function updatePriceOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "Invalid oracle");
        priceOracle = IPriceOracle(newOracle);
    }
} 