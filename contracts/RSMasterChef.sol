// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RSOptionsRewards.sol";

contract RSMasterChef is ReentrancyGuard, Ownable {
    struct UserInfo {
        uint256 amount;           // LP tokens provided
        uint256 rewardDebt;       // Reward debt
        uint256 lastRewardTime;   // Last time rewards were claimed
    }

    struct PoolInfo {
        IERC20 lpToken;           // LP token address
        uint256 allocPoint;       // How many allocation points assigned to this pool
        uint256 lastRewardTime;   // Last time rewards were distributed
        uint256 accRewardPerShare; // Accumulated rewards per share
        address paymentToken;     // USDC or S for this pool's options
        bool isActive;            // Pool status
    }

    RSOptionsRewards public immutable optionsRewards;
    
    // Pool Info
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    
    // Rewards config
    uint256 public rewardPerSecond;
    uint256 public totalAllocPoint;
    
    // Time tracking
    uint256 public startTime;
    uint256 public constant REWARD_DURATION = 365 days;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event OptionsIssued(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        address _optionsRewards,
        uint256 _rewardPerSecond,
        uint256 _startTime
    ) {
        optionsRewards = RSOptionsRewards(_optionsRewards);
        rewardPerSecond = _rewardPerSecond;
        startTime = _startTime;
    }

    // Add a new LP pool
    function addPool(
        uint256 _allocPoint,
        IERC20 _lpToken,
        address _paymentToken,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        
        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint += _allocPoint;
        
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardTime: lastRewardTime,
            accRewardPerShare: 0,
            paymentToken: _paymentToken,
            isActive: true
        }));
    }

    // Update reward variables for all pools
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (poolInfo[pid].isActive) {
                updatePool(pid);
            }
        }
    }

    // Update reward variables of the given pool
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 reward = multiplier * rewardPerSecond * pool.allocPoint / totalAllocPoint;
        
        pool.accRewardPerShare += reward * 1e12 / lpSupply;
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        updatePool(_pid);
        
        if (user.amount > 0) {
            uint256 pending = user.amount * pool.accRewardPerShare / 1e12 - user.rewardDebt;
            if (pending > 0) {
                issueOptionsReward(msg.sender, pending, pool.paymentToken);
            }
        }
        
        if (_amount > 0) {
            pool.lpToken.transferFrom(msg.sender, address(this), _amount);
            user.amount += _amount;
        }
        
        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        require(user.amount >= _amount, "withdraw: not enough");
        
        updatePool(_pid);
        
        uint256 pending = user.amount * pool.accRewardPerShare / 1e12 - user.rewardDebt;
        if (pending > 0) {
            issueOptionsReward(msg.sender, pending, pool.paymentToken);
        }
        
        if (_amount > 0) {
            user.amount -= _amount;
            pool.lpToken.transfer(msg.sender, _amount);
        }
        
        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e12;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Issue options as rewards
    function issueOptionsReward(
        address _user,
        uint256 _amount,
        address _paymentToken
    ) internal {
        optionsRewards.issueOptionReward(_user, _amount, _paymentToken);
        emit OptionsIssued(_user, _pid, _amount);
    }

    // Helper function for reward multiplier
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        _from = _from > startTime ? _from : startTime;
        if (_to > startTime + REWARD_DURATION) {
            _to = startTime + REWARD_DURATION;
        }
        return _to - _from;
    }
} 