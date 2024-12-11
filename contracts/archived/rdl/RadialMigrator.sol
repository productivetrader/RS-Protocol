// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RadialMigrator is PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    IERC20 public oldToken;
    IERC20 public newToken;
    uint256 public migrationRate;
    
    // Migration tracking
    uint256 public totalMigrated;
    mapping(address => uint256) public userMigrations;
    
    event MigrationRateSet(uint256 newRate);
    event TokensMigrated(address indexed user, uint256 oldAmount, uint256 newAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _oldToken,
        address _newToken
    ) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        
        oldToken = IERC20(_oldToken);
        newToken = IERC20(_newToken);
        migrationRate = 1e18; // 1:1 by default
    }

    function migrate(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        
        // Calculate new tokens to be received
        uint256 newAmount = (amount * migrationRate) / 1e18;
        
        // Update migration tracking
        totalMigrated += amount;
        userMigrations[msg.sender] += amount;
        
        // Transfer tokens
        oldToken.safeTransferFrom(msg.sender, address(this), amount);
        newToken.safeTransfer(msg.sender, newAmount);
        
        emit TokensMigrated(msg.sender, amount, newAmount);
    }

    function setMigrationRate(uint256 _rate) external onlyOwner {
        migrationRate = _rate;
        emit MigrationRateSet(_rate);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
} 